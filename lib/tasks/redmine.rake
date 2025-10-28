# frozen_string_literal: true

namespace :redmine do
  desc "Fetch and store basic Redmine issues data for all configured projects"
  task fetch_issues: :environment do
    puts "Starting to fetch Redmine issues..."

    Settings.redmine.projects.each do |project_identifier|
      puts "\nFetching issues for project: #{project_identifier}"

      offset = 0
      total_fetched = 0

      loop do
        count = Redmine::StoreData.new(
          project_identifier: project_identifier,
          limit: Settings.redmine.max_limit,
          offset: offset
        ).execute

        total_fetched += count
        puts "  Fetched #{count} issues (offset: #{offset})"

        # Break if we've fetched all issues (less than limit returned)
        break if count < Settings.redmine.max_limit

        offset += Settings.redmine.max_limit
      end

      puts "Total issues fetched for #{project_identifier}: #{total_fetched}"
    end

    puts "\n✅ Completed fetching issues for all projects"
  end

  desc "Fetch and update detailed information for all stored issues"
  task update_issue_details: :environment do
    puts "Starting to update issue details..."

    issues = RedmineIssue.all
    total = issues.count
    updated = 0
    failed = 0

    puts "Total issues to update: #{total}"

    issues.find_each.with_index do |issue, index|
      print "\rProcessing #{index + 1}/#{total}..."

      begin
        Redmine::UpdateIssueDetails.new(issue.redmine_id).execute
        updated += 1
      rescue StandardError => e
        puts "\n❌ Failed to update issue #{issue.redmine_id}: #{e.message}"
        failed += 1
      end

      # Add small delay to avoid rate limiting
      sleep(0.1)
    end

    puts "\n\n✅ Completed updating issue details"
    puts "Updated: #{updated}, Failed: #{failed}"
  end

  desc "Fetch issues and update details for all configured projects (full sync)"
  task sync_all: :environment do
    Rake::Task["redmine:fetch_issues"].invoke
    Rake::Task["redmine:update_issue_details"].invoke
  end

  desc "Fetch issues for a specific project with optional date range"
  task :fetch_project, [ :project_identifier, :start_date, :end_date ] => :environment do |_t, args|
    project_identifier = args[:project_identifier]
    start_date = args[:start_date] ? Date.parse(args[:start_date]) : nil
    end_date = args[:end_date] ? Date.parse(args[:end_date]) : nil

    unless project_identifier
      puts "❌ Error: project_identifier is required"
      puts "Usage: rails redmine:fetch_project[minden2,2025-10-01,2025-10-27]"
      exit 1
    end

    puts "Fetching issues for project: #{project_identifier}"
    puts "Date range: #{start_date || 'default'} to #{end_date || 'default'}"

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
      puts "Fetched #{count} issues (offset: #{offset})"

      break if count < Settings.redmine.max_limit

      offset += Settings.redmine.max_limit
    end

    puts "\n✅ Total issues fetched: #{total_fetched}"
  end
end

