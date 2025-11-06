# Sample Prompt AI Cursor

Dự án Rails demo về cách sử dụng prompt trong Cursor AI để phát triển ứng dụng.

## Mục đích

Đây là dự án mới tinh được tạo ra để minh họa cách làm việc hiệu quả với Cursor AI thông qua các prompt cụ thể. Dự án tập trung vào việc tích hợp với Redmine API để fetch và lưu trữ dữ liệu User Story và Project.

## Technology Stack

- **Backend**: Ruby 3.4.2, Rails 8.0.2.1
- **Database**: MySQL 8.0
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Deployment**: Docker, Kamal
- **Configuration**: Config gem (quản lý settings)
- **Code Quality**: RuboCop, Brakeman

## Cấu trúc Docker

Dự án chạy hoàn toàn trong Docker containers. **TUYỆT ĐỐI KHÔNG** chạy các lệnh Rails, Ruby, Bundle, Database trực tiếp trên host machine.

### Services

- **web**: Rails application (port 3000)
- **db**: MySQL 8.0 database (development)
- **test_db**: MySQL 8.0 database (test)

### Quick Start

1. **Tạo file `.env` từ mẫu**:
   ```bash
   cp env.example .env
   # Chỉnh sửa .env nếu cần
   ```

2. **Khởi động containers**:
   ```bash
   docker compose up -d
   ```

3. **Setup database**:
   ```bash
   docker compose exec web rails db:create
   docker compose exec web rails db:migrate
   ```

4. **Truy cập ứng dụng**: http://localhost:3000

### Các lệnh thường dùng

Xem chi tiết trong file [DOCKER_DEVELOPMENT.md](DOCKER_DEVELOPMENT.md) hoặc `.cursor/rules/docker.mdc`

```bash
# Bundle install
docker compose exec web bundle install

# Rails console
docker compose exec web rails console

# Chạy migrations
docker compose exec web rails db:migrate

# Chạy tests
docker compose exec web rails test

# Xem logs
docker compose logs -f web
```

## Demo Tasks

### Task 1: Fetch User Stories từ Redmine

**Mục tiêu**: Fetch các data của User Story từ Redmine về thông qua API. **Chỉ cần fetch thành công, chưa cần lưu vào DB.**

**Các field cần fetch**:
- `redmine_id` - ID của issue trong Redmine
- `subject` - Tiêu đề của User Story
- `jp_request` - Mô tả yêu cầu (tiếng Nhật)
- `start_date` - Ngày bắt đầu
- `due_date` - Ngày kết thúc
- `assignee` - Người được giao
- `estimate` - Thời gian ước tính
- `spent_time` - Thời gian đã sử dụng
- `difficult_level` - Mức độ khó

**Yêu cầu**:
- Tạo service/class để tích hợp với Redmine API
- Fetch theo từng team chỉ định, không fetch toàn bộ
- Fetch trong khoảng thời gian chỉ định
- Nếu không chỉ định thời gian cụ thể thì lấy `created_at` từ **1 tháng trước** tới **hiện tại**
- In ra hoặc log data để verify fetch thành công

### Task 2: Lưu User Stories vào Database

**Mục tiêu**: Sử dụng service đã tạo ở Task 1, fetch User Stories từ các project được chỉ định và **lưu vào database**.

**Các project cần fetch**:

1. **Minden**
   - Project identifier: `minden2`

2. **Kuruma**
   - Project identifier: `usedcar-ex`
   - **Bỏ qua các sub project**

**Yêu cầu**:
- Tạo model `UserStory` với migration cho các field đã liệt kê ở Task 1
- Tạo model `Project` để lưu thông tin project (nếu cần)
- Fetch User Stories từ các project được chỉ định
- Nếu có chỉ định `start_time`, `end_time` thì fetch trong khoảng thời gian đó
- Nếu không thì fetch trong khoảng thời gian **1 tháng từ trước tới giờ**
- Lưu data vào database với xử lý duplicate (theo `redmine_id`)

## Configuration

### Environment Variables

File `.env` chứa các biến môi trường cần thiết:

```bash
# Database Configuration
DB_HOST=db
DB_USER=rails_user
DB_PASSWORD=password
MYSQL_ROOT_PASSWORD=password
MYSQL_DATABASE=sample_prompt_ai_cursor_development

# Rails Configuration
RAILS_ENV=development
RAILS_MAX_THREADS=5

# Redmine API Configuration (cần thêm)
REDMINE_URL=https://your-redmine-instance.com
REDMINE_API_KEY=your_api_key_here
```

### Config Gem

Dự án sử dụng gem `config` để quản lý settings:

- File cấu hình: `config/settings.yml` và `config/settings/{environment}.yml`
- Initializer: `config/initializers/config.rb`
- Biến môi trường với prefix `SETTINGS_*` sẽ tự động được load

Ví dụ:
```bash
SETTINGS_REDMINE_URL=https://redmine.example.com
SETTINGS_API_KEY=your_key
```

Sử dụng trong code:
```ruby
Settings.redmine_url
Settings.api_key
```

## Cấu trúc Project

```
app/
├── controllers/        # Controllers
├── models/           # Models (UserStory, Project, ...)
├── jobs/             # Background jobs cho fetch data
└── views/            # Views

config/
├── settings.yml       # Settings mặc định
├── settings/          # Settings theo environment
│   ├── development.yml
│   ├── production.yml
│   └── test.yml
└── initializers/
    └── config.rb     # Config gem setup

db/
├── migrate/          # Database migrations
└── seeds.rb          # Seed data
```

## Development

### Thêm gem mới

1. Thêm vào `Gemfile`
2. Chạy: `docker compose exec web bundle install`
3. Restart container nếu cần: `docker compose restart web`

### Tạo migration

```bash
docker compose exec web rails generate migration CreateUserStories
docker compose exec web rails db:migrate
```

### Chạy tests

```bash
docker compose exec web rails test
docker compose exec web rails test:system
```

### Code Quality

```bash
# RuboCop
docker compose exec web rubocop
docker compose exec web rubocop -a  # auto-correct

# Brakeman (security)
docker compose exec web brakeman
```

## Redmine API Integration

### Authentication

Redmine API sử dụng API key authentication. Thêm vào `.env`:

```bash
REDMINE_URL=https://your-redmine.com
REDMINE_API_KEY=your_api_key_here
```

### API Endpoints cần sử dụng

- **User Stories (Issues)**: `/issues.json`
- **Projects**: `/projects.json`
- **Project Issues**: `/projects/{identifier}/issues.json`

### Filter Parameters

- `created_on`: Filter theo ngày tạo
- `project_id`: Filter theo project
- `tracker_id`: Filter theo tracker (User Story)
- `status_id`: Filter theo status

## Notes

- File `.env` đã được gitignore, không commit vào git
- File `env.example` có thể commit để làm mẫu
- Tất cả lệnh Rails phải chạy trong Docker container
- Database data được persist trong Docker volumes

## License

MIT License
