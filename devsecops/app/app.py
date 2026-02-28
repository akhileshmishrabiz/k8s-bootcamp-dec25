from datetime import datetime

from flask import Flask, jsonify, request
from flask_migrate import Migrate

from config import Config
from models import Comment, Tag, Task, User, db

app = Flask(__name__)
app.config.from_object(Config)

db.init_app(app)
migrate = Migrate(app, db)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


# User endpoints
@app.route("/users", methods=["POST"])
def create_user():
    """Feature 1: Create a new user"""
    data = request.get_json()

    if not data or "username" not in data or "email" not in data:
        return jsonify({"error": "Username and email are required"}), 400

    if User.query.filter_by(username=data["username"]).first():
        return jsonify({"error": "Username already exists"}), 409

    if User.query.filter_by(email=data["email"]).first():
        return jsonify({"error": "Email already exists"}), 409

    user = User(username=data["username"], email=data["email"])
    db.session.add(user)
    db.session.commit()

    return jsonify(user.to_dict()), 201


@app.route("/users", methods=["GET"])
def get_users():
    """Feature 2: List all users"""
    users = User.query.all()
    return jsonify([user.to_dict() for user in users]), 200


@app.route("/users/<int:user_id>", methods=["GET"])
def get_user(user_id):
    """Feature 3: Get user by ID"""
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict()), 200


# Task endpoints
@app.route("/tasks", methods=["POST"])
def create_task():
    """Feature 4: Create a new task"""
    data = request.get_json()

    if not data or "title" not in data:
        return jsonify({"error": "Title is required"}), 400

    task = Task(
        title=data["title"],
        description=data.get("description"),
        status=data.get("status", "pending"),
        priority=data.get("priority", "medium"),
        user_id=data.get("user_id"),
    )

    if "due_date" in data:
        try:
            task.due_date = datetime.fromisoformat(data["due_date"])
        except ValueError:
            return jsonify({"error": "Invalid due_date format. Use ISO format"}), 400

    db.session.add(task)
    db.session.commit()

    return jsonify(task.to_dict()), 201


@app.route("/tasks", methods=["GET"])
def get_tasks():
    """Feature 5: List all tasks with optional filters"""
    query = Task.query

    # Filter by status
    status = request.args.get("status")
    if status:
        query = query.filter_by(status=status)

    # Filter by priority
    priority = request.args.get("priority")
    if priority:
        query = query.filter_by(priority=priority)

    # Filter by completion status
    completed = request.args.get("completed")
    if completed is not None:
        query = query.filter_by(completed=completed.lower() == "true")

    # Filter by user
    user_id = request.args.get("user_id")
    if user_id:
        query = query.filter_by(user_id=int(user_id))

    tasks = query.all()
    return jsonify([task.to_dict() for task in tasks]), 200


@app.route("/tasks/<int:task_id>", methods=["GET"])
def get_task(task_id):
    """Feature 6: Get task by ID"""
    task = Task.query.get_or_404(task_id)
    return jsonify(task.to_dict()), 200


@app.route("/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    """Feature 7: Update a task"""
    task = Task.query.get_or_404(task_id)
    data = request.get_json()

    if "title" in data:
        task.title = data["title"]
    if "description" in data:
        task.description = data["description"]
    if "status" in data:
        task.status = data["status"]
    if "priority" in data:
        task.priority = data["priority"]
    if "completed" in data:
        task.completed = data["completed"]
    if "user_id" in data:
        task.user_id = data["user_id"]
    if "due_date" in data:
        try:
            task.due_date = datetime.fromisoformat(data["due_date"])
        except ValueError:
            return jsonify({"error": "Invalid due_date format. Use ISO format"}), 400

    db.session.commit()
    return jsonify(task.to_dict()), 200


@app.route("/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    """Feature 8: Delete a task"""
    task = Task.query.get_or_404(task_id)
    db.session.delete(task)
    db.session.commit()
    return jsonify({"message": "Task deleted successfully"}), 200


@app.route("/tasks/<int:task_id>/complete", methods=["PATCH"])
def toggle_task_completion(task_id):
    """Feature 9: Mark task as complete/incomplete"""
    task = Task.query.get_or_404(task_id)
    task.completed = not task.completed
    db.session.commit()
    return jsonify(task.to_dict()), 200


@app.route("/tasks/search", methods=["GET"])
def search_tasks():
    """Feature 10: Search tasks by title or description"""
    query_text = request.args.get("q", "")

    if not query_text:
        return jsonify({"error": 'Query parameter "q" is required'}), 400

    tasks = Task.query.filter(
        db.or_(
            Task.title.ilike(f"%{query_text}%"),
            Task.description.ilike(f"%{query_text}%"),
        )
    ).all()

    return jsonify([task.to_dict() for task in tasks]), 200


# Tag endpoints
@app.route("/tags", methods=["POST"])
def create_tag():
    """Feature 11: Create a new tag"""
    data = request.get_json()

    if not data or "name" not in data:
        return jsonify({"error": "Tag name is required"}), 400

    existing_tag = Tag.query.filter_by(name=data["name"]).first()
    if existing_tag:
        return jsonify({"error": "Tag already exists"}), 409

    tag = Tag(name=data["name"])
    db.session.add(tag)
    db.session.commit()

    return jsonify(tag.to_dict()), 201


@app.route("/tags", methods=["GET"])
def get_tags():
    """Feature 12: List all tags"""
    tags = Tag.query.all()
    return jsonify([tag.to_dict() for tag in tags]), 200


@app.route("/tasks/<int:task_id>/tags", methods=["POST"])
def add_tag_to_task(task_id):
    """Feature 13: Add tag to a task"""
    task = Task.query.get_or_404(task_id)
    data = request.get_json()

    if not data or "tag_id" not in data:
        return jsonify({"error": "Tag ID is required"}), 400

    tag = Tag.query.get_or_404(data["tag_id"])

    if tag in task.tags:
        return jsonify({"error": "Tag already added to this task"}), 409

    task.tags.append(tag)
    db.session.commit()

    return jsonify(task.to_dict()), 200


@app.route("/tasks/<int:task_id>/tags/<int:tag_id>", methods=["DELETE"])
def remove_tag_from_task(task_id, tag_id):
    """Feature 14: Remove tag from a task"""
    task = Task.query.get_or_404(task_id)
    tag = Tag.query.get_or_404(tag_id)

    if tag not in task.tags:
        return jsonify({"error": "Tag not found on this task"}), 404

    task.tags.remove(tag)
    db.session.commit()

    return jsonify(task.to_dict()), 200


# Comment endpoints
@app.route("/tasks/<int:task_id>/comments", methods=["POST"])
def add_comment(task_id):
    """Feature 15: Add comment to a task"""
    Task.query.get_or_404(task_id)
    data = request.get_json()

    if not data or "content" not in data:
        return jsonify({"error": "Comment content is required"}), 400

    comment = Comment(content=data["content"], task_id=task_id)
    db.session.add(comment)
    db.session.commit()

    return jsonify(comment.to_dict()), 201


@app.route("/tasks/<int:task_id>/comments", methods=["GET"])
def get_task_comments(task_id):
    """Get all comments for a task"""
    task = Task.query.get_or_404(task_id)
    return jsonify([comment.to_dict() for comment in task.comments]), 200


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Resource not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0", port=5000, debug=True)
