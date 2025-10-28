# frozen_string_literal: true

# Model for storing Redmine issues
class RedmineIssue < ApplicationRecord
  # Validations
  validates :redmine_id, presence: true, uniqueness: true

  # Scopes for common queries
  scope :by_project, ->(project_id) { where(redmine_project_id: project_id) }
  scope :by_date_range, ->(start_date, end_date) { where(start_date: start_date..end_date) }
  scope :recent, -> { order(created_at: :desc) }
end

