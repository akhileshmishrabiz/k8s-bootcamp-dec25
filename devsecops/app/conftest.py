import pytest

from app import app as flask_app
from models import db as _db


@pytest.fixture(scope="session")
def app():
    """Create application for the tests."""
    flask_app.config["TESTING"] = True
    flask_app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"

    with flask_app.app_context():
        _db.create_all()
        yield flask_app
        _db.drop_all()


@pytest.fixture(scope="function")
def db(app):
    """Create database for the tests."""
    with app.app_context():
        _db.session.begin_nested()
        yield _db
        _db.session.rollback()
        _db.session.remove()


@pytest.fixture
def client(app, db):
    """Create a test client for the app."""
    return app.test_client()
