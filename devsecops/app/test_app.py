import json

import pytest

from models import Task, User


class TestUsers:
    """Test user-related endpoints (Feature 1, 2, 3)"""

    def test_create_user(self, client, db):
        """Test creating a new user"""
        response = client.post(
            "/users",
            data=json.dumps({"username": "testuser", "email": "test@example.com"}),
            content_type="application/json",
        )

        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["username"] == "testuser"
        assert data["email"] == "test@example.com"
        assert "id" in data

    def test_create_user_duplicate_username(self, client, db):
        """Test creating user with duplicate username fails"""
        client.post(
            "/users",
            data=json.dumps({"username": "testuser", "email": "test1@example.com"}),
            content_type="application/json",
        )

        response = client.post(
            "/users",
            data=json.dumps({"username": "testuser", "email": "test2@example.com"}),
            content_type="application/json",
        )

        assert response.status_code == 409
        data = json.loads(response.data)
        assert "already exists" in data["error"]

    def test_create_user_missing_fields(self, client, db):
        """Test creating user without required fields fails"""
        response = client.post(
            "/users",
            data=json.dumps({"username": "testuser"}),
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_get_users(self, client, db):
        """Test getting all users"""
        client.post(
            "/users",
            data=json.dumps({"username": "user1", "email": "user1@example.com"}),
            content_type="application/json",
        )
        client.post(
            "/users",
            data=json.dumps({"username": "user2", "email": "user2@example.com"}),
            content_type="application/json",
        )

        response = client.get("/users")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 2


class TestTasks:
    """Test task-related endpoints (Feature 4, 5, 7)"""

    def test_create_task(self, client, db):
        """Test creating a new task"""
        response = client.post(
            "/tasks",
            data=json.dumps(
                {
                    "title": "Test Task",
                    "description": "This is a test task",
                    "priority": "high",
                }
            ),
            content_type="application/json",
        )

        assert response.status_code == 201
        data = json.loads(response.data)
        assert data["title"] == "Test Task"
        assert data["description"] == "This is a test task"
        assert data["priority"] == "high"
        assert data["status"] == "pending"
        assert not data["completed"]

    def test_create_task_missing_title(self, client, db):
        """Test creating task without title fails"""
        response = client.post(
            "/tasks",
            data=json.dumps({"description": "No title"}),
            content_type="application/json",
        )

        assert response.status_code == 400

    def test_get_tasks(self, client, db):
        """Test getting all tasks"""
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 1"}),
            content_type="application/json",
        )
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 2", "status": "completed"}),
            content_type="application/json",
        )

        response = client.get("/tasks")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 2

    def test_get_tasks_filter_by_status(self, client, db):
        """Test filtering tasks by status"""
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 1", "status": "pending"}),
            content_type="application/json",
        )
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 2", "status": "completed"}),
            content_type="application/json",
        )

        response = client.get("/tasks?status=completed")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 1
        assert data[0]["status"] == "completed"

    def test_get_tasks_filter_by_priority(self, client, db):
        """Test filtering tasks by priority"""
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 1", "priority": "low"}),
            content_type="application/json",
        )
        client.post(
            "/tasks",
            data=json.dumps({"title": "Task 2", "priority": "high"}),
            content_type="application/json",
        )

        response = client.get("/tasks?priority=high")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 1
        assert data[0]["priority"] == "high"

    def test_update_task(self, client, db):
        """Test updating a task"""
        create_response = client.post(
            "/tasks",
            data=json.dumps({"title": "Original Task"}),
            content_type="application/json",
        )
        task_id = json.loads(create_response.data)["id"]

        response = client.put(
            f"/tasks/{task_id}",
            data=json.dumps(
                {"title": "Updated Task", "status": "in_progress", "completed": True}
            ),
            content_type="application/json",
        )

        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["title"] == "Updated Task"
        assert data["status"] == "in_progress"
        assert data["completed"]

    def test_update_nonexistent_task(self, client, db):
        """Test updating a task that doesn't exist"""
        response = client.put(
            "/tasks/9999",
            data=json.dumps({"title": "Updated"}),
            content_type="application/json",
        )

        assert response.status_code == 404


class TestTaskSearch:
    """Test task search functionality (Feature 10)"""

    def test_search_tasks_by_title(self, client, db):
        """Test searching tasks by title"""
        client.post(
            "/tasks",
            data=json.dumps(
                {"title": "Python Development", "description": "Learn Flask"}
            ),
            content_type="application/json",
        )
        client.post(
            "/tasks",
            data=json.dumps({"title": "Java Tutorial", "description": "Learn Spring"}),
            content_type="application/json",
        )

        response = client.get("/tasks/search?q=Python")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 1
        assert "Python" in data[0]["title"]

    def test_search_tasks_by_description(self, client, db):
        """Test searching tasks by description"""
        client.post(
            "/tasks",
            data=json.dumps(
                {"title": "Task 1", "description": "Learn Flask framework"}
            ),
            content_type="application/json",
        )
        client.post(
            "/tasks",
            data=json.dumps(
                {"title": "Task 2", "description": "Learn Django framework"}
            ),
            content_type="application/json",
        )

        response = client.get("/tasks/search?q=Flask")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 1
        assert "Flask" in data[0]["description"]

    def test_search_tasks_no_query(self, client, db):
        """Test search without query parameter"""
        response = client.get("/tasks/search")
        assert response.status_code == 400

    def test_search_tasks_case_insensitive(self, client, db):
        """Test search is case insensitive"""
        client.post(
            "/tasks",
            data=json.dumps({"title": "Python Development"}),
            content_type="application/json",
        )

        response = client.get("/tasks/search?q=python")
        assert response.status_code == 200
        data = json.loads(response.data)
        assert len(data) == 1
