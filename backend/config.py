import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'medicore-dev-secret-key-change-in-production')
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///medicore.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
    JWT_EXPIRATION_HOURS = 24 * 7  # 7 days
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB max upload
