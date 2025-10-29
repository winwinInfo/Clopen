
import os
from dotenv import load_dotenv
from datetime import timedelta
from pathlib import Path

# 로컬 환경 변수 로드
load_dotenv()


class Config:
    # Basic Flask Configuration
    SECRET_KEY  = os.getenv('SECRET_KEY', 'dev-secret-key') # JWT 서명용 (차준직이 로그인 할 때 사용함)
    DEBUG       = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    
    # Database Configuration (AWS RDS 연결용)
    DB_HOST     = os.getenv('DATABASE_URL')
    DB_PORT     = os.getenv('DATABASE_port', '3306')
    DB_USER     = os.getenv('DATABASE_user', 'admin')
    DB_PASSWORD = os.getenv('DATABASE_password')
    DB_NAME     = os.getenv('DATABASE_name', 'cagongDB')

    # MySQL connection string
    SQLALCHEMY_DATABASE_URI = (
        f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
        f'?charset=utf8mb4'
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = DEBUG
    
    # JWT Configuration
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    # JWT 기본 설정
    JWT_TOKEN_LOCATION = ["headers"]
    JWT_HEADER_NAME = "Authorization"
    JWT_HEADER_TYPE = "Bearer"

    # Google ID 토큰 audience 검증용
    GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')

    # 프론트엔드 URL (추가)
    FRONTEND_URL = os.getenv('FRONTEND_URL', 'http://localhost:8080')

    # TOSS 결제 비밀키 (추가)
    TOSS_SECRET_KEY = os.getenv('TOSS_SECRET_KEY')

    # CORS Configuration
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', 'http://localhost:3000').split(',')
    
    # Firebase Configuration (for migration)
    FIREBASE_PROJECT_ID = os.getenv('FIREBASE_PROJECT_ID')
    FIREBASE_CREDENTIALS_PATH = os.getenv('FIREBASE_CREDENTIALS_PATH')

class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_ECHO = True

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_ECHO = False

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
