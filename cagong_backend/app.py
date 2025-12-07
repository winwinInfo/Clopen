from flask import Flask
from flask_cors import CORS
from routes.auth import auth_bp
from routes import register_blueprints
from models import init_db
from swagger import init_swagger
import os
from dotenv import load_dotenv
from flask_jwt_extended import JWTManager
from config import config
from exceptions.handlers import register_handlers

# 환경 변수에서 환경 설정 가져오기 (기본값: development)
# 시스템 환경 변수 또는 이전에 설정된 FLASK_ENV 확인
env = os.getenv('FLASK_ENV', 'development')

# 환경에 따라 다른 .env 파일 로드
# production → .env.prd
# development → .env.local (없으면 .env)
if env == 'production':
    env_file = '.env.prd'
else:
    env_file = '.env.local' if os.path.exists('.env.local') else '.env'

# .env 파일 로드
if os.path.exists(env_file):
    load_dotenv(env_file)
    print(f"Loaded environment from: {env_file}")
else:
    load_dotenv()  # 기본 .env 로드
    print(f"Loaded environment from: .env (default)")

# Flask 앱 생성
app = Flask(__name__)
# 환경별 설정 로드 (development 또는 production)
app.config.from_object(config.get(env, config['default']))

# CORS 설정
CORS(app, resources={
    r"/api/*": {
        "origins": app.config['CORS_ORIGINS'],
        "methods": ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True
    }
})

jwt = JWTManager(app)

register_handlers(app)
# Swagger 초기화
init_swagger(app)

# 블루프린트 등록 (routes/__init__.py에서 관리)
register_blueprints(app)

# db 초기화
init_db(app)



if __name__ == '__main__':
    # 설정에서 DEBUG 값을 가져와 사용
    app.run(debug=app.config['DEBUG'], port=5000)
