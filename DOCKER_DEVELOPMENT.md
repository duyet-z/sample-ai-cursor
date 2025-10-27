# Docker Development Setup

This Rails application has been configured for Docker-based development.

## Quick Start

1. **Initial Setup** (first time only):
   ```bash
   ./docker-dev.sh setup
   ```

2. **Start Development Environment**:
   ```bash
   ./docker-dev.sh up
   ```
   
   The application will be available at: http://localhost:3000

3. **Stop Development Environment**:
   ```bash
   ./docker-dev.sh down
   ```

## Available Commands

Use the `docker-dev.sh` script for common tasks:

- `./docker-dev.sh setup` - Initial setup (build, create and migrate database)
- `./docker-dev.sh up` - Start the development environment
- `./docker-dev.sh down` - Stop the development environment
- `./docker-dev.sh logs` - Show web container logs
- `./docker-dev.sh rails <command>` - Run rails commands (e.g., `./docker-dev.sh rails console`)
- `./docker-dev.sh bash` - Open bash shell in web container
- `./docker-dev.sh test` - Run test suite
- `./docker-dev.sh clean` - Clean up containers and volumes

## Services

The Docker Compose setup includes:

- **web**: Rails application (Ruby 3.4.2, Rails 8.0.2.1)
  - Port: 3000
  - Volume mounted for live code reloading
- **db**: MySQL 8.0 for development
  - Port: 3306
  - Database: `sample_prompt_ai_cursor_development`
  - User: `rails_user` / Password: `password`
- **test_db**: MySQL 8.0 for testing
  - Port: 3307
  - Database: `sample_prompt_ai_cursor_test`

## Environment Variables

The following environment variables are configured:

- `DATABASE_URL`: Points to the MySQL container
- `RAILS_ENV`: Set to `development`
- `DB_HOST`: MySQL host (`db` for development, `test_db` for testing)
- `DB_USER`: Database user (`rails_user`)
- `DB_PASSWORD`: Database password (`password`)

## File Structure

- `Dockerfile.dev`: Development-specific Dockerfile
- `docker-compose.yml`: Multi-service development setup
- `docker-dev.sh`: Helper script for common tasks
- `.dockerignore`: Files to ignore during build

## Development Workflow

1. Make code changes in your local editor
2. Changes are automatically reflected in the running container
3. Use `./docker-dev.sh rails console` to access Rails console
4. Use `./docker-dev.sh bash` to access container shell
5. Run tests with `./docker-dev.sh test`

## Database Access

To access the MySQL database directly:

```bash
# From host machine
mysql -h 127.0.0.1 -P 3306 -u rails_user -p sample_prompt_ai_cursor_development

# From within the web container
./docker-dev.sh bash
mysql -h db -u rails_user -p sample_prompt_ai_cursor_development
```

## Troubleshooting

- If containers fail to start, try: `./docker-dev.sh clean && ./docker-dev.sh setup`
- Check logs with: `./docker-dev.sh logs`
- Rebuild containers: `docker compose build --no-cache`

## Production Notes

This setup is for development only. The production `Dockerfile` is separate and optimized for deployment.