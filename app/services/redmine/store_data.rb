# frozen_string_literal: true

module Redmine
  # Service to fetch and store Redmine issues into database
  # Usage: Redmine::StoreData.new(project_identifier, options).execute
  class StoreData
    MAX_LIMIT = 100

    def initialize(project_identifier, options = {})
      @project_identifier = project_identifier
      @start_time = parse_date(options[:start_time])
      @end_time = parse_date(options[:end_time])
      @limit = [options[:limit].to_i, MAX_LIMIT].min
      @offset = options[:offset].to_i
    end

    # Fetch issues and store into database
    def execute
      response = fetch_issues
      return { success: false, message: "No issues found" } if response["issues"].blank?

      stored_count = 0
      errors = []

      response["issues"].each do |issue_data|
        issue_details = fetch_issue_details(issue_data["id"])
        store_issue(issue_details["issue"])
        stored_count += 1
      rescue => e
        errors << { issue_id: issue_data["id"], error: e.message }
      end

      {
        success: true,
        total_count: response["total_count"],
        stored_count: stored_count,
        errors: errors
      }
    end

    private

    # Fetch issues list
    def fetch_issues
      params = {
        limit: @limit,
        offset: @offset,
        start_time: @start_time,
        end_time: @end_time
      }.compact

      Redmine::FetchIssues.new(@project_identifier, params).execute
    end

    # Fetch single issue details
    def fetch_issue_details(issue_id)
      Redmine::FetchIssueDetails.new(issue_id).execute
    end

    # Store or update issue in database
    def store_issue(issue_data)
      issue = Issue.find_or_initialize_by(redmine_id: issue_data["id"])
      issue.assign_attributes(
        subject: issue_data["subject"],
        jp_request: extract_custom_field(issue_data, 16), # JP Request field id
        start_date: issue_data["start_date"],
        due_date: issue_data["due_date"],
        assignee: issue_data.dig("assigned_to", "name"),
        estimate: issue_data["total_estimated_hours"],
        spent_time: issue_data["total_spent_hours"],
        difficult_level: extract_custom_field(issue_data, 30), # Difficulty Level field id
        redmine_project_id: issue_data.dig("project", "id")
      )
      issue.save!
    end

    # Extract custom field value by field id
    def extract_custom_field(issue_data, field_id)
      custom_field = issue_data["custom_fields"]&.find { |cf| cf["id"] == field_id }
      custom_field&.dig("value")
    end

    # Parse date string to Date object
    def parse_date(date_string)
      return nil if date_string.blank?
      Date.parse(date_string.to_s)
    rescue ArgumentError
      nil
    end
  end
end

