# Redmine User Story Fetcher

Service để fetch User Stories từ Redmine API với đầy đủ pagination và filtering.

## 📋 Features

- ✅ Fetch User Stories từ multiple projects (teams)
- ✅ Hỗ trợ pagination (100 records/lần, fetch cho tới hết)
- ✅ Filter theo khoảng thời gian (start_date, end_date)
- ✅ Default: fetch từ 1 tháng trước tới hiện tại
- ✅ Parse đầy đủ 9 fields yêu cầu + bonus fields
- ✅ Log chi tiết để verify
- ✅ Export ra JSON file

## 🔧 Configuration

Configuration được lưu trong `config/settings/development.yml`:

```yaml
redmine:
  url: "https://dev.zigexn.vn"
  api_key: "your_api_key"
  basic_auth:
    username: "your_username"
    password: "your_password"
  tracker_id: 12  # User story tracker
  projects:
    - "minden2"
    - "usedcar-ex"  # Cần verify identifier đúng
  page_size: 100
```

## 📦 Fields được fetch

| Field | Redmine API Source | Note |
|-------|-------------------|------|
| `redmine_id` | `issue.id` | ID của issue |
| `subject` | `issue.subject` | Tiêu đề User Story |
| `jp_request` | `custom_fields[id=16].value` | Custom Field "JP Request" |
| `start_date` | `issue.start_date` | ✅ Ngày bắt đầu |
| `due_date` | `issue.due_date` | ✅ Ngày kết thúc |
| `assignee` | `issue.assigned_to.name` | Người được giao |
| `estimate` | `issue.estimated_hours` hoặc `total_estimated_hours` | ✅ Thời gian ước tính (hours) |
| `spent_time` | `issue.total_spent_hours` | ⚠️ Cần `fetch_spent_hours: true` |
| `difficult_level` | `custom_fields[id=30].value` | Custom Field "Difficulty Level" |

### ⚠️ Important: Spent Time Field

**Mặc định `spent_time` sẽ là `null`** vì Redmine list API không trả về field này.

Để lấy spent_time, cần bật option `fetch_spent_hours: true`:
```ruby
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  fetch_spent_hours: true  # Cần extra API call cho mỗi issue (chậm hơn)
)
```

**Trade-off:**
- `fetch_spent_hours: false` (default): Nhanh ⚡ nhưng spent_time = null
- `fetch_spent_hours: true`: Chậm hơn 🐢 nhưng có đầy đủ data

📖 Chi tiết: Xem `SPENT_HOURS_GUIDE.md`

**Bonus fields:**
- `status` - Trạng thái (New, In Progress, Testing, etc.)
- `priority` - Độ ưu tiên (Low, Medium, High, Urgent)
- `author` - Người tạo issue
- `project` - Tên project
- `created_on` - Ngày tạo
- `updated_on` - Ngày cập nhật

## 🚀 Usage

### 1. Sử dụng trong Code

```ruby
# Fetch với config mặc định (bao gồm sub-projects)
fetcher = Redmine::UserStoryFetcher.new
user_stories = fetcher.fetch_all

# Fetch từ projects cụ thể
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  start_date: '2025-10-01',
  end_date: '2025-10-31'
)
user_stories = fetcher.fetch_all

# Fetch CHỈ project chính, KHÔNG bao gồm sub-projects
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['usedcar-ex'],
  include_subprojects: false  # Chỉ lấy Usedcar-EX, không lấy TCV, ChukosyaEx, etc.
)
user_stories = fetcher.fetch_all

# Process data
user_stories.each do |story|
  puts "#{story[:redmine_id]}: #{story[:subject]}"
  puts "  Assignee: #{story[:assignee]}"
  puts "  Estimate: #{story[:estimate]} hours"
end
```

### 2. Sử dụng Rake Tasks

#### Fetch và hiển thị User Stories

```bash
# Fetch với config mặc định (1 tháng trước đến nay)
docker compose exec web bin/rails redmine:fetch_user_stories

# Fetch từ projects cụ thể
docker compose exec web bin/rails redmine:fetch_user_stories PROJECTS=minden2

# Fetch với date range cụ thể
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2 \
  START_DATE=2025-10-01 \
  END_DATE=2025-10-31

# Fetch từ multiple projects
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2,usedcar-ex \
  START_DATE=2025-10-01 \
  END_DATE=2025-10-31

# Fetch KHÔNG bao gồm sub-projects
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=usedcar-ex \
  INCLUDE_SUBPROJECTS=false
# Result: Chỉ fetch Usedcar-EX (4 stories), không fetch TCV, ChukosyaEx, etc.

# Fetch BAO GỒM sub-projects (default)
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=usedcar-ex \
  INCLUDE_SUBPROJECTS=true
# Result: Fetch Usedcar-EX + TCV + ChukosyaEx V2 + New Sell Car (9 stories)
```

#### Fetch và save ra JSON file

```bash
docker compose exec web bin/rails redmine:fetch_and_save
# File sẽ được lưu tại: tmp/redmine_user_stories_YYYYMMDD_HHMMSS.json
```

### 3. Sử dụng trong Rails Console

```ruby
docker compose exec web bin/rails console

# Trong console:
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  start_date: Date.new(2025, 10, 1),
  end_date: Date.today
)

stories = fetcher.fetch_all
puts "Fetched #{stories.size} User Stories"

# Thống kê
stories.group_by { |s| s[:status] }.each do |status, group|
  puts "#{status}: #{group.size} stories"
end
```

## 📊 Output Examples

### Console Output

```
================================================================================
FETCHING USER STORIES FROM REDMINE
================================================================================

Configuration:
  Projects: minden2
  Date Range: 2025-10-27 to 2025-10-28
  Tracker: User Story (ID: 12)

--------------------------------------------------------------------------------

================================================================================
RESULTS: 6 User Stories fetched
================================================================================

1. User Story #106736
   Subject: #6628 MINDEN-3681【App】占い師プロフィールページのUI変更
   Project: MInden
   Assignee: Minh Nguyễn Bình
   Start Date: 2025-10-27
   Due Date: 2025-10-29
   Estimate: N/A hours
   Spent Time: N/A hours
   Difficulty Level: 1
   JP Request: https://2zigexn.backlog.com/view/MINDEN-3681
   Status: Waiting Release
   Priority: Medium
   Created: 2025-10-27T13:50:54+07:00
   ------------------------------------------------------------------------------

================================================================================
SUMMARY BY PROJECT
================================================================================
  MInden: 6 User Stories
    - Total Estimate: 0.0 hours
    - Total Spent: 0.0 hours
    - Avg Difficulty: 1.0
```

### JSON Output

```json
[
  {
    "redmine_id": 106736,
    "subject": "#6628 MINDEN-3681【App】占い師プロフィールページのUI変更",
    "jp_request": "https://2zigexn.backlog.com/view/MINDEN-3681",
    "start_date": "2025-10-27",
    "due_date": "2025-10-29",
    "assignee": "Minh Nguyễn Bình",
    "estimate": null,
    "spent_time": null,
    "difficult_level": "1",
    "status": "Waiting Release",
    "priority": "Medium",
    "author": "Lưu Nguyễn",
    "project": "MInden",
    "created_on": "2025-10-27T13:50:54+07:00",
    "updated_on": "2025-11-05T16:58:38+07:00"
  }
]
```

## 🌳 Sub-Projects Behavior

**Quan trọng:** Trong Redmine, một project có thể có sub-projects (quan hệ cha-con).

### Default Behavior (include_subprojects: true)

Khi fetch một project, **mặc định sẽ fetch cả sub-projects** của nó.

**Ví dụ:** Project `usedcar-ex` có các sub-projects:
- TCV (ID: 94)
- ChukosyaEx V2 (ID: 139)
- New Sell Car
- Usedcar-EX (ID: 90) - project chính

Khi fetch với `include_subprojects: true` (default):
- ✅ Fetch User Stories từ TẤT CẢ các projects trên
- Result: 9 User Stories

### Chỉ fetch project chính (include_subprojects: false)

Khi fetch với `include_subprojects: false`:
- ✅ Fetch User Stories CHỈ từ project chính
- ❌ KHÔNG fetch từ sub-projects
- Result: 4 User Stories (chỉ Usedcar-EX)

### Khi nào nên dùng gì?

| Use Case | Setting | Lý do |
|----------|---------|-------|
| Muốn toàn bộ User Stories của team/department | `include_subprojects: true` | Lấy tất cả công việc liên quan |
| Muốn chỉ User Stories của project cụ thể | `include_subprojects: false` | Tách biệt công việc giữa các projects |
| Không biết project có sub-projects không | `include_subprojects: true` | Safe default |

## 🔍 Troubleshooting

### Không fetch được data

**Kiểm tra:**
1. Project identifier đúng chưa? (VD: `minden2` chứ không phải `minden`)
2. Date range có User Stories không?
3. Tracker ID đúng chưa? (12 = User story)
4. API credentials còn valid không?

**Cách tìm project identifier:**

```bash
# List tất cả projects
curl --location 'https://dev.zigexn.vn/projects.json?limit=200' \
  --header 'X-Redmine-API-Key: your_api_key' | python3 -m json.tool

# Hoặc check một project cụ thể bằng ID
curl --location 'https://dev.zigexn.vn/projects/92.json' \
  --header 'X-Redmine-API-Key: your_api_key' | python3 -m json.tool
```

### Custom fields không đúng

Nếu custom fields của bạn khác, cần update constants trong service:

```ruby
# app/services/redmine/user_story_fetcher.rb
JP_REQUEST_FIELD_ID = 16  # Update ID này
DIFFICULTY_LEVEL_FIELD_ID = 30  # Update ID này
```

## 📝 Notes

- Service sử dụng built-in `Net::HTTP` của Ruby, không cần thêm gem dependencies
- Pagination tự động với 100 records/lần (có thể config trong `settings.yml`)
- Rate limiting: Redmine API thường có rate limit, service chưa implement retry logic
- Chỉ fetch, chưa lưu vào database (theo yêu cầu)

## 🔗 API Documentation

Redmine API docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues

## ⚙️ Next Steps (Optional)

Nếu cần lưu vào database:
1. Tạo model `UserStory` với migration
2. Implement `save_to_database` method trong service
3. Handle duplicate detection (check by `redmine_id`)
4. Add background job để fetch định kỳ

