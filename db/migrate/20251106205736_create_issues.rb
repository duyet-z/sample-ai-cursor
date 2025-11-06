class CreateIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :issues do |t|
      t.integer :redmine_id, null: false
      t.text :subject
      t.string :jp_request
      t.date :start_date
      t.date :due_date
      t.string :assignee
      t.decimal :estimate, precision: 10, scale: 2
      t.decimal :spent_time, precision: 10, scale: 2
      t.string :difficult_level
      t.integer :redmine_project_id

      t.timestamps
    end
    add_index :issues, :redmine_id, unique: true
  end
end
