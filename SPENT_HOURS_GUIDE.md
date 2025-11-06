# 🕐 Spent Hours & Estimate Fields Guide

## ❓ Vấn đề

Trong Redmine API, các fields sau **KHÔNG được trả về** khi fetch list issues:
- ❌ `spent_hours` / `total_spent_hours`
- ⚠️ `total_estimated_hours` (chỉ có `estimated_hours`)

**Chỉ khi fetch single issue với `include=time_entries`** thì mới có đầy đủ data.

## ✅ Giải pháp Implemented

Service hỗ trợ **2 modes**:

### Mode 1: Fast (default) ⚡
Fetch list nhanh, **KHÔNG** lấy spent_hours (sẽ là `null`)

### Mode 2: Accurate (opt-in) 🎯
Fetch thêm spent_hours bằng cách gọi API riêng cho **từng issue** (chậm hơn)

## 📊 So sánh Performance

| Mode | Speed | Estimate Data | Spent Time Data | API Calls |
|------|-------|---------------|-----------------|-----------|
| **Fast** (default) | ⚡ Nhanh | `estimated_hours` only | ❌ Null | N (N = số issues) |
| **Accurate** | 🐢 Chậm | `total_estimated_hours` | ✅ Full data | N + N (double calls) |

**Ví dụ:** Fetch 100 User Stories
- Fast mode: **100 API calls** (~5-10 seconds)
- Accurate mode: **200 API calls** (~20-30 seconds)

## 🚀 Usage

### 1️⃣ Fast Mode (Default) - Không lấy spent_hours

```bash
# Via Rake Task
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2 \
  START_DATE=2025-10-01 \
  END_DATE=2025-10-31
# hoặc explicit
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2 \
  FETCH_SPENT_HOURS=false
```

**Trong Code:**
```ruby
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  fetch_spent_hours: false  # default
)
stories = fetcher.fetch_all

# Result:
# {
#   estimate: 1.0,         # từ estimated_hours
#   spent_time: nil        # KHÔNG có data
# }
```

### 2️⃣ Accurate Mode - Lấy đầy đủ spent_hours

```bash
# Via Rake Task
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=minden2 \
  START_DATE=2025-10-01 \
  END_DATE=2025-10-31 \
  FETCH_SPENT_HOURS=true
```

**Trong Code:**
```ruby
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  fetch_spent_hours: true  # Bật mode chính xác
)
stories = fetcher.fetch_all

# Result:
# {
#   estimate: 14.0,        # từ total_estimated_hours
#   spent_time: 21.5       # ✅ Có đầy đủ data
# }
```

## 📈 Test Results

### Test với Issue #106516

**Fast Mode:**
```
Estimate: N/A hours
Spent Time: N/A hours
```

**Accurate Mode:**
```
Estimate: 14.0 hours     ✅
Spent Time: 21.5 hours   ✅
```

### Test với Issue #106651

**Fast Mode:**
```
Estimate: N/A hours
Spent Time: N/A hours
```

**Accurate Mode:**
```
Estimate: 0.0 hours      ✅ (chưa estimate)
Spent Time: 3.0 hours    ✅
```

## 💡 Khi nào dùng gì?

### ✅ Dùng **Fast Mode** (default) khi:
- Cần fetch nhanh để overview
- Không cần thống kê spent_time
- Fetch số lượng lớn User Stories (>50)
- Chỉ quan tâm title, status, assignee
- Development/testing

**Use Cases:**
- Dashboard overview
- Quick status check
- List all User Stories
- Filter và search

### ✅ Dùng **Accurate Mode** khi:
- Cần báo cáo chính xác về effort
- Thống kê estimate vs actual
- So sánh performance giữa các assignees
- End-of-sprint reports
- Billing/invoicing

**Use Cases:**
- Sprint retrospective
- Team productivity reports
- Budget tracking
- Time tracking audit

## ⚠️ Trade-offs

### Fast Mode Advantages:
- ✅ Nhanh (~5-10 seconds cho 100 issues)
- ✅ Ít tải cho server
- ✅ Safe cho large datasets
- ❌ Thiếu spent_time data

### Accurate Mode Advantages:
- ✅ Đầy đủ data (estimate + spent_time)
- ✅ Chính xác cho reporting
- ❌ Chậm (~20-30 seconds cho 100 issues)
- ❌ Nhiều API calls (double)
- ❌ Có thể hit rate limit

## 🔧 Technical Details

### API Behavior

**List API (`/issues.json`):**
```json
{
  "id": 106516,
  "estimated_hours": 1.0,        // ✅ Có
  "total_estimated_hours": null, // ❌ KHÔNG có
  "spent_hours": null,           // ❌ KHÔNG có
  "total_spent_hours": null      // ❌ KHÔNG có
}
```

**Single Issue API (`/issues/106516.json?include=time_entries`):**
```json
{
  "id": 106516,
  "estimated_hours": 1.0,         // ✅ Có
  "total_estimated_hours": 14.0,  // ✅ Có
  "spent_hours": 0.0,             // ✅ Có
  "total_spent_hours": 21.5       // ✅ Có
}
```

### Implementation

Service fetch spent_hours bằng cách:
1. Fetch list issues (fast)
2. Nếu `fetch_spent_hours: true`, loop qua từng issue
3. Call `/issues/{id}.json?include=time_entries` cho mỗi issue
4. Enrich data với `total_estimated_hours` và `total_spent_hours`

```ruby
# app/services/redmine/user_story_fetcher.rb

def enrich_with_spent_hours!(story, issue_id)
  details = fetch_issue_details(issue_id)
  return unless details

  story[:estimate] = details["total_estimated_hours"] || details["estimated_hours"]
  story[:spent_time] = details["total_spent_hours"] || details["spent_hours"] || 0.0
end
```

## 📝 Notes

1. **Default behavior:** `fetch_spent_hours: false` - để performance tốt hơn
2. **Rate limiting:** Accurate mode có thể hit rate limit nếu fetch quá nhiều issues
3. **Retry logic:** Chưa implement retry khi API fails
4. **Caching:** Có thể cache results để tránh re-fetch
5. **Batch processing:** Có thể optimize bằng concurrent requests (future improvement)

## 🎯 Recommendations

### For Development:
```ruby
# Fast mode - đủ để develop và test
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  fetch_spent_hours: false
)
```

### For Production Reports:
```ruby
# Accurate mode - đầy đủ data cho reports
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  start_date: Date.new(2025, 10, 1),
  end_date: Date.new(2025, 10, 31),
  fetch_spent_hours: true
)
```

### For Large Datasets:
```ruby
# Fetch fast first, then enrich only needed issues
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['minden2'],
  fetch_spent_hours: false
)
stories = fetcher.fetch_all

# Enrich only in-progress or specific stories
important_stories = stories.select { |s| s[:status] == 'In Progress' }
# ... fetch spent_hours cho chỉ những stories này
```

## 🔗 Related Documentation

- Main service README: `app/services/redmine/README.md`
- Integration guide: `REDMINE_INTEGRATION.md`
- Sub-projects behavior: `SUB_PROJECTS_GUIDE.md`

## ❓ FAQ

**Q: Tại sao không mặc định fetch spent_hours?**

A: Vì sẽ chậm gấp đôi. Hầu hết use cases không cần spent_time data ngay lập tức.

**Q: Có cách nào nhanh hơn không?**

A: Có thể implement concurrent requests, nhưng cần cẩn thận với rate limiting.

**Q: estimated_hours vs total_estimated_hours khác gì?**

A:
- `estimated_hours`: Estimate của issue chính
- `total_estimated_hours`: Tổng estimate bao gồm cả sub-tasks/children issues

**Q: Tương tự với spent_hours?**

A: Đúng vậy:
- `spent_hours`: Time log trên issue chính
- `total_spent_hours`: Tổng time log bao gồm sub-tasks

---

**Status: ✅ Implemented & Tested**

