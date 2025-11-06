# frozen_string_literal: true

module Redmine
  # Service to fetch single issue details from Redmine
  # Usage: Redmine::FetchIssueDetails.new(issue_id).execute
  class FetchIssueDetails
    def initialize(issue_id)
      @issue_id = issue_id
    end

    # Fetch issue details with journals and watchers
    def execute
      endpoint = "/issues/#{@issue_id}.json?include=journals,watchers"
      Redmine::FetchData.new(endpoint).perform
    end
  end
end

