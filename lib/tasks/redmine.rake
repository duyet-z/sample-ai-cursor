# frozen_string_literal: true

namespace :redmine do
  desc "Fetch User Stories from Redmine and display results"
  task fetch_user_stories: :environment do
    puts "\n" + "=" * 80
    puts "FETCHING USER STORIES FROM REDMINE"
    puts "=" * 80

    # Setup
    projects = ENV["PROJECTS"]&.split(",") || Settings.redmine.projects
    start_date = ENV["START_DATE"] || 1.month.ago.to_date.to_s
    end_date = ENV["END_DATE"] || Date.today.to_s
    include_subprojects = ENV["INCLUDE_SUBPROJECTS"] != "false" # default: true
    fetch_spent_hours = ENV["FETCH_SPENT_HOURS"] == "true" # default: false (chậm)

    puts "\nConfiguration:"
    puts "  Projects: #{projects.join(', ')}"
    puts "  Date Range: #{start_date} to #{end_date}"
    puts "  Tracker: User Story (ID: #{Settings.redmine.tracker_id})"
    puts "  Include Sub-projects: #{include_subprojects ? 'Yes' : 'No'}"
    puts "  Fetch Spent Hours: #{fetch_spent_hours ? 'Yes (slower, extra API calls)' : 'No (faster)'}"
    puts "\n" + "-" * 80

    # Fetch stories
    fetcher = Redmine::UserStoryFetcher.new(
      projects: projects,
      start_date: start_date,
      end_date: end_date,
      include_subprojects: include_subprojects,
      fetch_spent_hours: fetch_spent_hours
    )

    user_stories = fetcher.fetch_all

    puts "\n" + "=" * 80
    puts "RESULTS: #{user_stories.size} User Stories fetched"
    puts "=" * 80

    # Display results
    if user_stories.empty?
      puts "\nNo User Stories found."
    else
      user_stories.each_with_index do |story, index|
        puts "\n#{index + 1}. User Story ##{story[:redmine_id]}"
        puts "   Subject: #{story[:subject]}"
        puts "   Project: #{story[:project]}"
        puts "   Assignee: #{story[:assignee] || 'N/A'}"
        puts "   Start Date: #{story[:start_date] || 'N/A'}"
        puts "   Due Date: #{story[:due_date] || 'N/A'}"
        puts "   Estimate: #{story[:estimate] || 'N/A'} hours"
        puts "   Spent Time: #{story[:spent_time] || 'N/A'} hours"
        puts "   Difficulty Level: #{story[:difficult_level] || 'N/A'}"
        puts "   JP Request: #{story[:jp_request]}" if story[:jp_request].present?
        puts "   Status: #{story[:status]}"
        puts "   Priority: #{story[:priority]}"
        puts "   Created: #{story[:created_on]}"
        puts "   " + "-" * 78
      end

      # Summary by project
      puts "\n" + "=" * 80
      puts "SUMMARY BY PROJECT"
      puts "=" * 80
      grouped = user_stories.group_by { |s| s[:project] }
      grouped.each do |project, stories|
        puts "  #{project}: #{stories.size} User Stories"

        # Stats
        total_estimate = stories.sum { |s| s[:estimate].to_f }
        total_spent = stories.sum { |s| s[:spent_time].to_f }
        avg_difficulty = stories.map { |s| s[:difficult_level].to_i }.compact.then do |levels|
          levels.empty? ? 0 : levels.sum.to_f / levels.size
        end

        puts "    - Total Estimate: #{total_estimate.round(2)} hours"
        puts "    - Total Spent: #{total_spent.round(2)} hours"
        puts "    - Avg Difficulty: #{avg_difficulty.round(2)}"
      end
    end

    puts "\n" + "=" * 80
    puts "DONE!"
    puts "=" * 80 + "\n"
  end

  desc "Fetch User Stories and save to JSON file"
  task fetch_and_save: :environment do
    puts "Fetching User Stories from Redmine..."

    fetcher = Redmine::UserStoryFetcher.new
    user_stories = fetcher.fetch_all

    # Save to file
    filename = "tmp/redmine_user_stories_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json"
    File.write(filename, JSON.pretty_generate(user_stories))

    puts "Saved #{user_stories.size} User Stories to: #{filename}"
  end
end

