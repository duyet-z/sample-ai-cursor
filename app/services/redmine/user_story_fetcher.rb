# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Redmine
  # Service to fetch User Stories from Redmine API
  # Usage:
  #   fetcher = Redmine::UserStoryFetcher.new(
  #     projects: ['minden2', 'usedcar-ex'],
  #     start_date: '2025-10-01',
  #     end_date: '2025-10-31',
  #     include_subprojects: true,  # default: true (fetch cả sub-projects)
  #     fetch_spent_hours: true     # default: false (cần extra API calls, chậm hơn)
  #   )
  #   user_stories = fetcher.fetch_all
  class UserStoryFetcher
    attr_reader :projects, :start_date, :end_date, :config, :include_subprojects, :fetch_spent_hours

    # Custom fields IDs from Redmine
    JP_REQUEST_FIELD_ID = 16
    DIFFICULTY_LEVEL_FIELD_ID = 30

    def initialize(projects: nil, start_date: nil, end_date: nil, include_subprojects: true, fetch_spent_hours: false)
      @config = Settings.redmine
      @projects = projects || @config.projects
      @start_date = start_date || 1.month.ago.to_date
      @end_date = end_date || Date.today
      @include_subprojects = include_subprojects
      @fetch_spent_hours = fetch_spent_hours
    end

    # Fetch all User Stories from all projects with pagination
    # @return [Array<Hash>] Array of parsed user stories
    def fetch_all
      all_stories = []

      @projects.each do |project_id|
        Rails.logger.info "Fetching User Stories from project: #{project_id}"
        stories = fetch_project_stories(project_id)
        all_stories.concat(stories)
      end

      Rails.logger.info "Total User Stories fetched: #{all_stories.size}"
      all_stories
    end

    private

    # Fetch User Stories from a single project with pagination
    def fetch_project_stories(project_id)
      offset = 0
      limit = @config.page_size
      all_issues = []
      total_count = nil

      loop do
        Rails.logger.info "  Fetching page: offset=#{offset}, limit=#{limit}"

        response = fetch_issues(project_id, offset, limit)

        break unless response["issues"]

        issues = response["issues"]
        total_count ||= response["total_count"]

        # Parse and add issues
        parsed_issues = issues.map do |issue|
          story = parse_user_story(issue)
          # Fetch spent hours if requested (requires additional API call per issue)
          if @fetch_spent_hours
            enrich_with_spent_hours!(story, issue["id"])
          end
          story
        end
        all_issues.concat(parsed_issues)

        Rails.logger.info "  Fetched #{issues.size} issues (Total: #{all_issues.size}/#{total_count})"

        # Check if we've fetched all
        break if all_issues.size >= total_count

        offset += limit
      end

      all_issues
    end

    # Fetch issues from Redmine API
    def fetch_issues(project_id, offset, limit)
      uri = build_uri(project_id, offset, limit)

      request = Net::HTTP::Get.new(uri)
      request["X-Redmine-API-Key"] = @config.api_key
      request["Content-Type"] = "application/json"
      request.basic_auth(@config.basic_auth.username, @config.basic_auth.password)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      if response.code.to_i == 200
        JSON.parse(response.body)
      else
        Rails.logger.error "Failed to fetch issues: #{response.code} - #{response.body}"
        {}
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching issues: #{e.message}"
      {}
    end

    # Build URI for Redmine API request
    def build_uri(project_id, offset, limit)
      date_filter = "#{@start_date}|#{@end_date}"
      query_params = {
        project_id: project_id,
        tracker_id: @config.tracker_id,
        created_on: "><#{date_filter}",
        offset: offset,
        limit: limit
      }

      # Exclude sub-projects if requested
      # subproject_id=!* means "no sub-projects"
      query_params[:subproject_id] = "!*" unless @include_subprojects

      uri = URI("#{@config.url}/issues.json")
      uri.query = URI.encode_www_form(query_params)
      uri
    end

    # Parse User Story issue to extract required fields
    def parse_user_story(issue)
      {
        redmine_id: issue["id"],
        subject: issue["subject"],
        jp_request: extract_custom_field(issue, JP_REQUEST_FIELD_ID),
        start_date: issue["start_date"],
        due_date: issue["due_date"],
        assignee: issue.dig("assigned_to", "name"),
        estimate: issue["estimated_hours"] || issue["total_estimated_hours"],
        spent_time: issue["spent_hours"] || issue["total_spent_hours"],
        difficult_level: extract_custom_field(issue, DIFFICULTY_LEVEL_FIELD_ID),
        # Additional useful fields
        status: issue.dig("status", "name"),
        priority: issue.dig("priority", "name"),
        author: issue.dig("author", "name"),
        project: issue.dig("project", "name"),
        created_on: issue["created_on"],
        updated_on: issue["updated_on"]
      }
    end

    # Extract custom field value by ID
    def extract_custom_field(issue, field_id)
      custom_fields = issue["custom_fields"] || []
      field = custom_fields.find { |cf| cf["id"] == field_id }
      field&.dig("value")
    end

    # Fetch detailed issue to get spent_hours (requires additional API call)
    def fetch_issue_details(issue_id)
      uri = URI("#{@config.url}/issues/#{issue_id}.json?include=time_entries")

      request = Net::HTTP::Get.new(uri)
      request["X-Redmine-API-Key"] = @config.api_key
      request["Content-Type"] = "application/json"
      request.basic_auth(@config.basic_auth.username, @config.basic_auth.password)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(request)
      end

      if response.code.to_i == 200
        JSON.parse(response.body)["issue"]
      else
        Rails.logger.error "Failed to fetch issue #{issue_id} details: #{response.code}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "Error fetching issue #{issue_id} details: #{e.message}"
      nil
    end

    # Enrich story with spent_hours data from detailed issue API
    def enrich_with_spent_hours!(story, issue_id)
      details = fetch_issue_details(issue_id)
      return unless details

      # Update estimate and spent_time with more complete data
      story[:estimate] = details["total_estimated_hours"] || details["estimated_hours"]
      story[:spent_time] = details["total_spent_hours"] || details["spent_hours"] || 0.0
    end
  end
end

