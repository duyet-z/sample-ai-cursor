# frozen_string_literal: true

namespace :redmine do
  desc "Fetch and store Redmine issues for all configured projects"
  task fetch_issues: :environment do
    puts "=" * 80
    puts "Starting Redmine issues sync"
    puts "=" * 80

    projects = Settings.redmine.projects
    start_time = ENV["START_DATE"] || 30.days.ago.to_date.to_s
    end_time = ENV["END_DATE"] || Date.today.to_s

    puts "\nProjects: #{projects.join(', ')}"
    puts "Date range: #{start_time} to #{end_time}"
    puts "-" * 80

    total_stored = 0
    all_errors = []

    projects.each do |project_identifier|
      puts "\n[#{project_identifier}] Starting sync..."
      project_stored = 0
      offset = 0
      limit = 100

      loop do
        puts "  Fetching offset #{offset}..."

        result = Redmine::StoreData.new(
          project_identifier,
          start_time: start_time,
          end_time: end_time,
          limit: limit,
          offset: offset
        ).execute

        unless result[:success]
          puts "  #{result[:message]}"
          break
        end

        project_stored += result[:stored_count]
        all_errors.concat(result[:errors]) if result[:errors].present?

        puts "  Stored: #{result[:stored_count]}/#{result[:total_count]}"

        # Break if we've processed all issues
        break if offset + limit >= result[:total_count]

        offset += limit
      end

      puts "[#{project_identifier}] Completed: #{project_stored} issues stored"
      total_stored += project_stored
    end

    puts "\n" + "=" * 80
    puts "Sync completed!"
    puts "Total issues stored: #{total_stored}"

    if all_errors.present?
      puts "\nErrors (#{all_errors.count}):"
      all_errors.each do |error|
        puts "  Issue ##{error[:issue_id]}: #{error[:error]}"
      end
    end
    puts "=" * 80
  end

  desc "Fetch and store Redmine issues for a specific project"
  task :fetch_project, [:project_identifier] => :environment do |_t, args|
    project_identifier = args[:project_identifier]

    unless project_identifier
      puts "Usage: rake redmine:fetch_project[project_identifier]"
      puts "Example: rake redmine:fetch_project[minden2]"
      exit 1
    end

    puts "=" * 80
    puts "Fetching issues for project: #{project_identifier}"
    puts "=" * 80

    start_time = ENV["START_DATE"] || 30.days.ago.to_date.to_s
    end_time = ENV["END_DATE"] || Date.today.to_s
    offset = 0
    limit = 100
    total_stored = 0

    loop do
      puts "\nFetching offset #{offset}..."

      result = Redmine::StoreData.new(
        project_identifier,
        start_time: start_time,
        end_time: end_time,
        limit: limit,
        offset: offset
      ).execute

      unless result[:success]
        puts result[:message]
        break
      end

      total_stored += result[:stored_count]
      puts "Stored: #{result[:stored_count]}/#{result[:total_count]}"

      if result[:errors].present?
        puts "Errors:"
        result[:errors].each do |error|
          puts "  Issue ##{error[:issue_id]}: #{error[:error]}"
        end
      end

      break if offset + limit >= result[:total_count]

      offset += limit
    end

    puts "\n" + "=" * 80
    puts "Completed! Total stored: #{total_stored}"
    puts "=" * 80
  end
end

