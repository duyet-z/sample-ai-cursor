# frozen_string_literal: true

module Redmine
  # Service to fetch issues list from Redmine
  # Usage: Redmine::FetchIssues.new(project_identifier, params).execute
  class FetchIssues
    def initialize(project_identifier, params = {})
      @project_identifier = project_identifier
      @params = params
    end

    # Fetch issues and return response
    def execute
      endpoint = build_endpoint
      Redmine::FetchData.new(endpoint).perform
    end

    private

    # Build endpoint URL with query params
    def build_endpoint
      query_params = {
        project_id: @project_identifier,
        tracker_id: Settings.redmine.trackers.user_story,
        limit: @params[:limit] || 100,
        offset: @params[:offset] || 0
      }

      # Add date filters if provided
      query_params[:created_on] = date_range_filter if @params[:start_time] || @params[:end_time]

      "/issues.json?#{URI.encode_www_form(query_params.compact)}"
    end

    # Build date range filter (>=start_date|<=end_date)
    def date_range_filter
      start_date = @params[:start_time] || 30.days.ago.to_date
      end_date = @params[:end_time] || Date.today
      "><#{start_date}|#{end_date}"
    end
  end
end

