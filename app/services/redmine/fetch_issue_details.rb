# frozen_string_literal: true

module Redmine
  # Service to fetch detailed information for a specific Redmine issue
  # Usage: Redmine::FetchIssueDetails.new(106160).execute
  class FetchIssueDetails
    attr_reader :issue_id

    def initialize(issue_id)
      @issue_id = issue_id
    end

    # Fetch and return detailed issue information
    # Returns hash with parsed fields or raises error
    def execute
      endpoint = "issues/#{issue_id}.json"
      response = Redmine::FetchData.new(endpoint).perform

      parse_issue_data(response["issue"])
    end

    private

    # Parse issue data into structured hash
    def parse_issue_data(issue)
      {
        redmine_id: issue["id"],
        subject: issue["subject"],
        jp_request: extract_custom_field_value(issue, "JP Request"),
        start_date: issue["start_date"],
        due_date: issue["due_date"],
        assignee: issue.dig("assigned_to", "name"),
        estimate: issue["total_estimated_hours"],
        spent_time: issue["total_spent_hours"],
        difficult_level: extract_custom_field_value(issue, "Difficulty Level"),
        redmine_project_id: issue.dig("project", "id")
      }
    end

    # Extract custom field value by name
    def extract_custom_field_value(issue, field_name)
      custom_field = issue["custom_fields"]&.find { |cf| cf["name"] == field_name }
      custom_field&.dig("value")
    end
  end
end

