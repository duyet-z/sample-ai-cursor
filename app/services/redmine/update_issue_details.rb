# frozen_string_literal: true

module Redmine
  # Service to fetch and update detailed information for a Redmine issue
  # Usage: Redmine::UpdateIssueDetails.new(106160).execute
  class UpdateIssueDetails
    attr_reader :issue_id

    def initialize(issue_id)
      @issue_id = issue_id
    end

    # Fetch details and update database record
    # Returns updated RedmineIssue record or raises error
    def execute
      issue_data = Redmine::FetchIssueDetails.new(issue_id).execute

      update_issue(issue_data)
    end

    private

    # Update or create issue record with detailed data
    def update_issue(data)
      issue = RedmineIssue.find_or_initialize_by(redmine_id: data[:redmine_id])
      issue.update!(data)
      issue
    end
  end
end

