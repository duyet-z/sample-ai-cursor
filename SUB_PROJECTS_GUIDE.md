# 🌳 Redmine Sub-Projects Guide

## TL;DR

**Redmine projects có thể có sub-projects. Mặc định, khi fetch một project, sẽ fetch cả sub-projects của nó.**

## 🔍 Ví dụ thực tế

### Project: `usedcar-ex`

```
usedcar-ex (parent)
├── TCV
├── ChukosyaEx V2
├── New Sell Car
└── Usedcar-EX (main project)
```

## 📊 So sánh kết quả

| Mode | Command | User Stories | Projects Fetched |
|------|---------|--------------|------------------|
| **WITH sub-projects** (default) | `INCLUDE_SUBPROJECTS=true` | **9 stories** | ✅ Usedcar-EX<br>✅ TCV<br>✅ ChukosyaEx V2<br>✅ New Sell Car |
| **WITHOUT sub-projects** | `INCLUDE_SUBPROJECTS=false` | **4 stories** | ✅ Usedcar-EX only |

## 💡 Test Commands

### 1️⃣ Fetch WITH sub-projects (default)

```bash
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=usedcar-ex \
  START_DATE=2025-10-01 \
  END_DATE=2025-11-06
```

**Output:**
```
Configuration:
  Include Sub-projects: Yes

RESULTS: 9 User Stories fetched

Projects:
  - TCV: 3 stories
  - Usedcar-EX: 4 stories
  - ChukosyaEx V2: 1 story
  - New Sell Car: 1 story
```

### 2️⃣ Fetch WITHOUT sub-projects

```bash
docker compose exec web bin/rails redmine:fetch_user_stories \
  PROJECTS=usedcar-ex \
  START_DATE=2025-10-01 \
  END_DATE=2025-11-06 \
  INCLUDE_SUBPROJECTS=false
```

**Output:**
```
Configuration:
  Include Sub-projects: No

RESULTS: 4 User Stories fetched

Projects:
  - Usedcar-EX: 4 stories (only)
```

## 🎯 Khi nào dùng gì?

### ✅ Dùng `include_subprojects: true` (default) khi:
- Muốn overview toàn bộ công việc của team/department
- Cần thống kê tổng hợp nhiều projects liên quan
- Không chắc project có sub-projects hay không
- Muốn báo cáo tổng thể

**Example:**
```ruby
# Fetch tất cả User Stories liên quan đến usedcar-ex team
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['usedcar-ex'],
  include_subprojects: true  # default
)
stories = fetcher.fetch_all
# => 9 stories từ Usedcar-EX, TCV, ChukosyaEx, New Sell Car
```

### ✅ Dùng `include_subprojects: false` khi:
- Chỉ quan tâm công việc của một project cụ thể
- Cần tách biệt rõ ràng công việc giữa các projects
- Muốn thống kê chính xác cho từng project riêng lẻ
- Muốn tránh duplicate khi fetch nhiều projects

**Example:**
```ruby
# Fetch CHỈ User Stories của project Usedcar-EX chính
fetcher = Redmine::UserStoryFetcher.new(
  projects: ['usedcar-ex'],
  include_subprojects: false
)
stories = fetcher.fetch_all
# => 4 stories chỉ từ Usedcar-EX
```

## 🔧 Technical Details

### API Parameter

Service sử dụng parameter `subproject_id=!*` trong Redmine API để exclude sub-projects:

```ruby
# With sub-projects (default)
GET /issues.json?project_id=usedcar-ex&tracker_id=12

# Without sub-projects
GET /issues.json?project_id=usedcar-ex&tracker_id=12&subproject_id=!*
```

### Code Implementation

```ruby
# app/services/redmine/user_story_fetcher.rb

def build_uri(project_id, offset, limit)
  query_params = {
    project_id: project_id,
    tracker_id: @config.tracker_id,
    created_on: "><#{date_filter}",
    offset: offset,
    limit: limit
  }

  # Exclude sub-projects if requested
  query_params[:subproject_id] = "!*" unless @include_subprojects

  # ...
end
```

## 📝 Notes

1. **Default behavior:** `include_subprojects: true` - để đảm bảo không bỏ sót User Stories
2. **Performance:** Fetch với sub-projects có thể chậm hơn nếu có nhiều sub-projects
3. **Duplicate detection:** Nếu fetch nhiều projects, có thể cần check duplicate issues
4. **Project structure:** Có thể thay đổi theo thời gian, nên verify định kỳ

## 🔗 Related Documentation

- Full documentation: `app/services/redmine/README.md`
- Main integration guide: `REDMINE_INTEGRATION.md`
- Redmine API docs: https://www.redmine.org/projects/redmine/wiki/Rest_Issues

## ❓ FAQ

**Q: Làm sao biết một project có sub-projects không?**

A: Check trong Redmine web interface hoặc query API:
```bash
curl 'https://dev.zigexn.vn/projects/usedcar-ex.json' \
  --header 'X-Redmine-API-Key: your_key'
```

**Q: Có thể fetch chỉ một số sub-projects cụ thể không?**

A: Không trực tiếp. Cần fetch tất cả rồi filter trong code, hoặc fetch từng sub-project riêng lẻ.

**Q: Sub-projects có nhiều cấp (nested) thì sao?**

A: Redmine API sẽ fetch tất cả sub-projects ở mọi cấp khi `include_subprojects: true`.

