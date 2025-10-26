from flask import Flask
from routes import register_blueprints
from models import init_db
import os
from dotenv import load_dotenv
from flask_jwt_extended import JWTManager
from config import Config

# .env 파일 로드
load_dotenv()

# 간단한 Flask 앱 생성
app = Flask(__name__)

app.config.from_object(Config)

jwt = JWTManager(app)

# 블루프린트 등록 (routes/__init__.py에서 관리)
register_blueprints(app)

# db 초기화
init_db(app)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
