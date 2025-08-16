from flask import Flask
from flask_cors import CORS
from routes.auth import auth_bp
from routes import register_blueprints
import os
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# 간단한 Flask 앱 생성
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'simple-secret-key')
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key')
app.config['GOOGLE_CLIENT_ID'] = os.getenv('GOOGLE_WEB_CLIENT_ID')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite3'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 블루프린트 등록 (routes/__init__.py에서 관리)
register_blueprints(app)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
