from flask import Flask
from flask_cors import CORS
from models.User import db
from routes.auth import auth_bp


def create_app():
    app = Flask(__name__)

    # 🔐 CORS 설정 (Flutter와 통신 허용)
    CORS(app, origins=["http://localhost:3000", "http://127.0.0.1:3000", "*"])

    # 🔑 DB 설정 (SQLite 사용)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///db.sqlite3'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # 🧱 DB 초기화
    db.init_app(app)

    # 🛣️ Blueprint 등록
    app.register_blueprint(auth_bp, url_prefix='/api/auth')

    return app


if __name__ == '__main__':
    app = create_app()

    # db.sqlite3가 없다면 테이블 생성
    with app.app_context():
        db.create_all()

    app.run(debug=True)
