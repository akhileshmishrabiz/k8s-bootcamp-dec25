# Task Management System

A comprehensive Flask-based task management REST API with PostgreSQL database.

## Features

This application includes 15 features:

### User Management
1. **Create User** - Register new users with username and email
2. **List Users** - Get all registered users
3. **Get User by ID** - Retrieve specific user details

### Task Management
4. **Create Task** - Create new tasks with title, description, priority, status, and due date
5. **List Tasks** - Get all tasks with optional filters (status, priority, completion, user)
6. **Get Task by ID** - Retrieve specific task details
7. **Update Task** - Modify task properties
8. **Delete Task** - Remove tasks from the system
9. **Toggle Task Completion** - Mark tasks as complete or incomplete

### Advanced Features
10. **Search Tasks** - Search tasks by title or description
11. **Create Tags** - Create reusable tags
12. **List Tags** - Get all available tags
13. **Add Tag to Task** - Associate tags with tasks
14. **Remove Tag from Task** - Disassociate tags from tasks
15. **Add Comments to Tasks** - Add comments/notes to tasks

## Tech Stack

- **Framework**: Flask 3.0
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy
- **Testing**: Pytest
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Clone the repository and navigate to the app directory

2. Build and run the application:
```bash
docker-compose up --build
```

3. The API will be available at `http://localhost:5000`

## Running Tests

Run tests inside the container:
```bash
docker-compose exec web pytest -v
```

Or run tests locally:
```bash
pip install -r requirements.txt
pytest -v
```

## API Endpoints

### Health Check
- `GET /health` - Health check endpoint

### Users
- `POST /users` - Create a new user
- `GET /users` - List all users
- `GET /users/<id>` - Get user by ID

### Tasks
- `POST /tasks` - Create a new task
- `GET /tasks` - List all tasks (supports filters: ?status=, ?priority=, ?completed=, ?user_id=)
- `GET /tasks/<id>` - Get task by ID
- `PUT /tasks/<id>` - Update a task
- `DELETE /tasks/<id>` - Delete a task
- `PATCH /tasks/<id>/complete` - Toggle task completion
- `GET /tasks/search?q=<query>` - Search tasks

### Tags
- `POST /tags` - Create a new tag
- `GET /tags` - List all tags
- `POST /tasks/<id>/tags` - Add tag to task
- `DELETE /tasks/<id>/tags/<tag_id>` - Remove tag from task

### Comments
- `POST /tasks/<id>/comments` - Add comment to task
- `GET /tasks/<id>/comments` - Get all comments for a task

## Example API Calls

### Create a User
```bash
curl -X POST http://localhost:5000/users \
  -H "Content-Type: application/json" \
  -d '{"username": "john_doe", "email": "john@example.com"}'
```

### Create a Task
```bash
curl -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project documentation",
    "description": "Write comprehensive README",
    "priority": "high",
    "status": "pending",
    "user_id": 1,
    "due_date": "2024-12-31T23:59:59"
  }'
```

### Search Tasks
```bash
curl http://localhost:5000/tasks/search?q=documentation
```

### Filter Tasks by Status
```bash
curl http://localhost:5000/tasks?status=completed
```

## Database Models

### User
- id (Primary Key)
- username (Unique)
- email (Unique)
- created_at

### Task
- id (Primary Key)
- title
- description
- status (pending, in_progress, completed)
- priority (low, medium, high)
- due_date
- completed (Boolean)
- user_id (Foreign Key)
- created_at
- updated_at

### Tag
- id (Primary Key)
- name (Unique)

### Comment
- id (Primary Key)
- content
- task_id (Foreign Key)
- created_at

## Test Coverage

Tests cover approximately 30% of features including:
- User creation and listing
- Task CRUD operations
- Task filtering
- Task updates
- Task search functionality

Run tests with coverage:
```bash
docker-compose exec web pytest --cov=. --cov-report=html
```

## Environment Variables

Copy `.env.example` to `.env` and configure:
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY` - Flask secret key

## CI/CD Pipeline

The project includes a comprehensive GitHub Actions workflow (`app-devsecops.yaml`) with **parallel execution** for faster feedback.

### Pipeline Stages (Parallel Optimized)

**Stage 1 - Parallel Quality & Security Checks:**
1. **Lint** - Code quality checks with Ruff
2. **Test** - Unit tests with Pytest and coverage reporting
3. **CodeQL** - Static application security testing (SAST)

**Stage 2 - Build & Scan:**
4. **Build** - Docker image build with caching (depends on lint + test)
5. **Scan** - Security scanning with Trivy (image and filesystem)

**Stage 3 - Deploy:**
6. **Push** - Push to GitHub Container Registry (main branch only, after all checks pass)

See [WORKFLOW.md](WORKFLOW.md) for detailed pipeline documentation and execution flow diagram.

### Running Locally

**Lint with Ruff:**
```bash
cd devsecops/app
pip install ruff
ruff check .
ruff format .
```

**Run tests:**
```bash
docker-compose exec web pytest -v
```

**Security scan with Trivy:**
```bash
docker build -t task-app:local .
trivy image task-app:local
```

## Development

To make changes:
1. Modify the code
2. Run linting: `ruff check . --fix`
3. Run tests: `docker-compose exec web pytest -v`
4. Restart the containers: `docker-compose restart web`

## Stopping the Application

```bash
docker-compose down
```

To remove volumes:
```bash
docker-compose down -v
```
