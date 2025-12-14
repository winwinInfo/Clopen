
import os
from dotenv import load_dotenv
from datetime import timedelta
from pathlib import Path

# 환경 감지 (기본값: development)
FLASK_ENV = os.getenv('FLASK_ENV', 'development')

# 환경별 .env 파일 선택 및 로드
if FLASK_ENV == 'production':
    env_file = '.env.prd'
elif os.path.exists('.env.local'):
    env_file = '.env.local'
else:
    env_file = '.env'

# .env 파일 로드
if os.path.exists(env_file):
    load_dotenv(env_file, override=True)
    print(f"[Config] Loaded environment from: {env_file}")
else:
    load_dotenv(override=True)
    print(f"[Config] Loaded environment from: .env (default)")


class Config:
    # Basic Flask Configuration
    SECRET_KEY  = os.getenv('SECRET_KEY', 'dev-secret-key') # JWT 서명용 (차준직이 로그인 할 때 사용함)
    DEBUG       = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    
    # Database Configuration
    DB_HOST     = os.getenv('DATABASE_URL')
    DB_PORT     = os.getenv('DATABASE_port', '3306')
    DB_USER     = os.getenv('DATABASE_user')
    DB_PASSWORD = os.getenv('DATABASE_password')
    DB_NAME     = os.getenv('DATABASE_name')

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

    # Google Maps/Places API 키
    GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

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
