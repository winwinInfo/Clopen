from flask import Flask
from flask_cors import CORS
from routes.auth import auth_bp
from routes import register_blueprints
from models import init_db
from swagger import init_swagger
from flask_jwt_extended import JWTManager
from config import config, FLASK_ENV
from exceptions.handlers import register_handlers

# Flask 앱 생성 및 환경별 설정 로드
app = Flask(__name__)
app.config.from_object(config.get(FLASK_ENV, config['default']))

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
