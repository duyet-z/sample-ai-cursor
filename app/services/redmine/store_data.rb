# frozen_string_literal: true

module Redmine
  # Service to fetch issues from Redmine API and store basic info in database
  # Usage: Redmine::StoreData.new(project_identifier: "minden2", start_time: Date.today - 30, end_time: Date.today, limit: 100, offset: 0).execute
  class StoreData
    attr_reader :project_identifier, :start_time, :end_time, :limit, :offset

    def initialize(project_identifier:, start_time: nil, end_time: nil, limit: Settings.redmine.max_limit, offset: 0)
      @project_identifier = project_identifier
      @start_time = start_time || (Date.today - Settings.redmine.default_days.days)
      @end_time = end_time || Date.today
      @limit = [ limit, Settings.redmine.max_limit ].min
      @offset = offset
    end

    # Fetch issues and store basic information (id, subject)
    # Returns count of stored issues
    def execute
      response = fetch_issues
      issues = response["issues"] || []

      store_issues(issues)

      issues.count
    end

    private

    # Build and fetch issues from Redmine API
    def fetch_issues
      endpoint = build_endpoint
      puts "endpoint: #{endpoint}"
      Redmine::FetchData.new(endpoint).perform
    end

    # Build API endpoint with query parameters
    # Redmine API requires created_on format: ><start_date|end_date
    def build_endpoint
      params = {
        project_id: project_identifier,
        tracker_id: Settings.redmine.tracker_id,
        created_on: "><#{start_time}|#{end_time}",
        limit: limit,
        offset: offset
      }

      "issues.json?#{URI.encode_www_form(params)}"
    end

    # Store basic issue information (only redmine_id and subject)
    # Will be updated later by FetchIssueDetails service
    def store_issues(issues)
      issues.each do |issue|
        RedmineIssue.find_or_create_by(redmine_id: issue["id"]) do |record|
          record.subject = issue["subject"]
          record.redmine_project_id = issue.dig("project", "id")
        end
      end
    end
  end
end

