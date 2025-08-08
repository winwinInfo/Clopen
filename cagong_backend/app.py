from flask import Flask
from flask_cors import CORS
from models.User import db
from routes.auth import auth_bp
from routes import register_blueprints


# 간단한 Flask 앱 생성
app = Flask(__name__)
app.config['SECRET_KEY'] = 'simple-secret-key'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite3'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False


# db.sqlite3가 없다면 테이블 생성
with app.app_context():
    db.create_all()


# 블루프린트 등록 (routes/__init__.py에서 관리)
register_blueprints(app)


if __name__ == '__main__':
    app.run(debug=True, port=5000)
