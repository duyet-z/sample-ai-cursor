# frozen_string_literal: true

# Controller for Redmine issues synchronization endpoints
class RedmineIssuesController < ApplicationController
  # POST /redmine_issues/sync
  # Params: project_identifier (required), start_date (optional), end_date (optional)
  def sync
    project_identifier = params[:project_identifier]

    unless project_identifier
      return render json: { error: "project_identifier is required" }, status: :bad_request
    end

    unless Settings.redmine.projects.include?(project_identifier)
      return render json: { error: "Invalid project_identifier. Allowed: #{Settings.redmine.projects.join(', ')}" },
                     status: :bad_request
    end

    start_date = params[:start_date] ? Date.parse(params[:start_date]) : nil
    end_date = params[:end_date] ? Date.parse(params[:end_date]) : nil

    # Fetch basic issues data
    total_fetched = fetch_issues_for_project(project_identifier, start_date, end_date)

    render json: {
      message: "Successfully fetched #{total_fetched} issues for project #{project_identifier}",
      total_fetched: total_fetched
    }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # POST /redmine_issues/update_details
  # Updates detailed information for all stored issues
  def update_details
    updated_count = 0
    failed_count = 0

    RedmineIssue.find_each do |issue|
      Redmine::UpdateIssueDetails.new(issue.redmine_id).execute
      updated_count += 1
    rescue StandardError => e
      Rails.logger.error("Failed to update issue #{issue.redmine_id}: #{e.message}")
      failed_count += 1
    end

    render json: {
      message: "Completed updating issue details",
      updated: updated_count,
      failed: failed_count
    }, status: :ok
  end

  # GET /redmine_issues
  # List all stored issues with optional filtering
  def index
    issues = RedmineIssue.all

    # Apply filters if provided
    issues = issues.by_project(params[:project_id]) if params[:project_id].present?
    issues = issues.where("start_date >= ?", params[:start_date]) if params[:start_date].present?
    issues = issues.where("due_date <= ?", params[:end_date]) if params[:end_date].present?

    issues = issues.recent.limit(params[:limit] || 100)

    render json: issues, status: :ok
  end

  private

  # Fetch all issues for a project with pagination
  def fetch_issues_for_project(project_identifier, start_date, end_date)
    offset = 0
    total_fetched = 0

    loop do
      count = Redmine::StoreData.new(
        project_identifier: project_identifier,
        start_time: start_date,
        end_time: end_date,
        limit: Settings.redmine.max_limit,
        offset: offset
      ).execute

      total_fetched += count

      break if count < Settings.redmine.max_limit

      offset += Settings.redmine.max_limit
    end

    total_fetched
  end
end

