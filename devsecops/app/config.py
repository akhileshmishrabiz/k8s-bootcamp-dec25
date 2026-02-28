import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")
    SQLALCHEMY_DATABASE_URI = os.getenv( "DATABASE_URL", "postgresql://postgres:postgres@db:5432/taskdb")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
