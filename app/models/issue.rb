class Issue < ApplicationRecord
  validates :redmine_id, presence: true, uniqueness: true
  validates :subject, presence: true
end
