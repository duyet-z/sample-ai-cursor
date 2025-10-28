# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_28_075450) do
  create_table "redmine_issues", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "redmine_id", null: false
    t.text "subject"
    t.string "jp_request"
    t.date "start_date"
    t.date "due_date"
    t.string "assignee"
    t.decimal "estimate", precision: 10, scale: 2
    t.decimal "spent_time", precision: 10, scale: 2
    t.integer "difficult_level"
    t.integer "redmine_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_redmine_issues_on_due_date"
    t.index ["redmine_id"], name: "index_redmine_issues_on_redmine_id", unique: true
    t.index ["redmine_project_id"], name: "index_redmine_issues_on_redmine_project_id"
    t.index ["start_date"], name: "index_redmine_issues_on_start_date"
  end

  create_table "user_stories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "redmine_id"
    t.integer "project_id"
    t.string "project_name"
    t.integer "tracker_id"
    t.string "tracker_name"
    t.integer "status_id"
    t.string "status_name"
    t.integer "priority_id"
    t.string "priority_name"
    t.integer "author_id"
    t.string "author_name"
    t.integer "assigned_to_id"
    t.string "assigned_to_name"
    t.integer "fixed_version_id"
    t.string "fixed_version_name"
    t.text "subject"
    t.text "description"
    t.date "start_date"
    t.date "due_date"
    t.integer "done_ratio"
    t.float "estimated_hours"
    t.float "total_estimated_hours"
    t.float "spent_hours"
    t.float "total_spent_hours"
    t.json "custom_fields"
    t.datetime "created_on"
    t.datetime "updated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["redmine_id"], name: "index_user_stories_on_redmine_id", unique: true
  end
end
