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

ActiveRecord::Schema[8.0].define(version: 2025_11_06_205736) do
  create_table "issues", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "redmine_id", null: false
    t.text "subject"
    t.string "jp_request"
    t.date "start_date"
    t.date "due_date"
    t.string "assignee"
    t.decimal "estimate", precision: 10, scale: 2
    t.decimal "spent_time", precision: 10, scale: 2
    t.string "difficult_level"
    t.integer "redmine_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["redmine_id"], name: "index_issues_on_redmine_id", unique: true
  end

  create_table "redmine_issues", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "redmine_id"
    t.string "subject"
    t.text "jp_request"
    t.date "start_date"
    t.date "due_date"
    t.string "assignee"
    t.decimal "estimate", precision: 10
    t.decimal "spent_time", precision: 10
    t.string "difficult_level"
    t.integer "redmine_project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["redmine_id"], name: "index_redmine_issues_on_redmine_id", unique: true
  end
end
