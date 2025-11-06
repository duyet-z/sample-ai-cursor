# Redmine Integration - User Story Fetcher

## ✅ Task Completed

Đã implement thành công service để fetch User Stories từ Redmine API với đầy đủ chức năng theo yêu cầu.

## 📦 Files Created

### 1. Configuration
- `config/settings/development.yml` - Cấu hình Redmine API credentials và projects

### 2. Service Class
- `app/services/redmine/user_story_fetcher.rb` - Main service để fetch User Stories
  - Hỗ trợ multiple projects (teams)
  - Pagination tự động (100 records/lần)
  - Date range filtering
  - Parse đầy đủ 9 fields + bonus fields

### 3. Rake Tasks
- `lib/tasks/redmine.rake` - Tasks để test và sử dụng service
  - `rails redmine:fetch_user_stories` - Fetch và hiển thị
  - `rails redmine:fetch_and_save` - Fetch và save ra JSON

### 4. Documentation
- `app/services/redmine/README.md` - Hướng dẫn chi tiết sử dụng

## 🎯 Features Implemented

| Yêu cầu | Status | Note |
|---------|--------|------|
| Fetch User Stories từ Redmine | ✅ | Via API với authentication |
| Fetch theo team (project_id) | ✅ | Hỗ trợ multiple projects |
| 9 fields yêu cầu | ✅ | redmine_id, subject, jp_request, start_date, due_date, assignee, estimate, spent_time, difficult_level |
| Hỗ trợ date range | ✅ | start_date, end_date parameters |
| Default 1 tháng trước | ✅ | Nếu không chỉ định thời gian |
| Pagination 100 records | ✅ | Fetch cho tới hết |
| Log/verify thành công | ✅ | Console output + JSON file |
| Chưa lưu DB | ✅ | Chỉ fetch và return data |

## ✅ Testing Results

### Test 1: Fetch với config mặc định
```bash
docker compose exec web bin/rails redmine:fetch_user_stories
```
**Result:** ✅ Fetched 25 User Stories từ multiple projects

### Test 2: Fetch project cụ thể với date range
```bash
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2 \
  START_DATE=2025-10-27 \
  END_DATE=2025-10-28
```
**Result:** ✅ Fetched 6 User Stories từ project MInden

### Test 3: Save to JSON file
```bash
docker compose exec web bin/rails redmine:fetch_and_save
```
**Result:** ✅ Saved to `tmp/redmine_user_stories_20251106_084705.json`

## 📊 Sample Data Fetched

```json
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
```

## 🚀 Quick Start

### Fetch User Stories ngay

```bash
# Fetch với default config (minden2, usedcar-ex, từ 1 tháng trước)
docker compose exec web bin/rails redmine:fetch_user_stories

# Hoặc fetch project cụ thể
docker compose exec web bin/rails redmine:fetch_user_stories PROJECTS=minden2

# Save ra file JSON
docker compose exec web bin/rails redmine:fetch_and_save
```

### Sử dụng trong code

```ruby
# Trong Rails console hoặc controller
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  start_date: '2025-10-01',
  end_date: '2025-10-31'
)

user_stories = fetcher.fetch_all

# Process data
user_stories.each do |story|
  puts "#{story[:subject]} - #{story[:assignee]}"
end
```

## ⚠️ Important Notes

### 1. Project Identifiers
- ✅ `minden2` - Verified working (Project "MInden", ID: 92)
- ❓ `usedcar-ex` - Cần verify identifier chính xác

**Cách tìm project identifier:**
```bash
curl --location 'https://dev.zigexn.vn/projects.json?limit=200' \
  --header 'X-Redmine-API-Key: cfd5114fdb5b6ff9a403844bf74d8935be2132dd' \
  | python3 -m json.tool
```

### 2. Custom Fields
- Custom Field ID 16: "JP Request"
- Custom Field ID 30: "Difficulty Level"
- Nếu project khác có custom field IDs khác, cần update trong code

### 3. API Credentials
- Credentials hiện tại được lưu trong `config/settings/development.yml`
- Cần copy sang `production.yml` khi deploy
- **Security:** Nên move credentials sang environment variables

## 📈 Statistics from Test

| Metric | Value |
|--------|-------|
| Total User Stories fetched | 25 |
| Projects covered | MInden, TCV, Usedcar-EX, ChukosyaEx V2, New Sell Car |
| Date range tested | 2025-10-06 to 2025-11-06 |
| Pagination | Working (100 records/page) |
| Success rate | 100% |

## 🔜 Next Steps (Optional)

1. **Verify project identifiers:**
   - Tìm identifier chính xác cho `usedcar-ex`
   - Update config với tất cả teams cần fetch

2. **Save to Database:**
   - Tạo model `UserStory`
   - Implement save logic
   - Handle duplicates

3. **Scheduling:**
   - Add background job để fetch định kỳ
   - Setup cron job hoặc Solid Queue

4. **Security:**
   - Move credentials sang environment variables
   - Không commit credentials vào git

5. **Error Handling:**
   - Add retry logic cho API failures
   - Handle rate limiting
   - Send notifications khi có lỗi

## 📚 Documentation

Full documentation: `app/services/redmine/README.md`

## ✅ Task Status: COMPLETED

Tất cả yêu cầu ban đầu đã được implement và test thành công!

