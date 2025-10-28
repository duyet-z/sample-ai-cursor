class CreateRedmineIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :redmine_issues do |t|
      t.integer :redmine_id, null: false
      t.text :subject
      t.string :jp_request
      t.date :start_date
      t.date :due_date
      t.string :assignee
      t.decimal :estimate, precision: 10, scale: 2
      t.decimal :spent_time, precision: 10, scale: 2
      t.integer :difficult_level
      t.integer :redmine_project_id

      t.timestamps
    end

    # Add indexes for performance
    add_index :redmine_issues, :redmine_id, unique: true
    add_index :redmine_issues, :redmine_project_id
    add_index :redmine_issues, :start_date
    add_index :redmine_issues, :due_date
  end
end
