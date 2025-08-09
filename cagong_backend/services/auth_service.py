from flask import current_app
from models.user import User, db
from google.oauth2 import id_token
from google.auth.transport import requests
import jwt
import datetime

def verify_google_token(id_token_str):
    try:
        idinfo = id_token.verify_oauth2_token(
            id_token_str,
            requests.Request(),
            # 환경변수 대신 config에서 가져오기
            current_app.config.get("GOOGLE_CLIENT_ID")  # 필요시 .env에 추가
        )
        return idinfo
    except ValueError:
        return None

def handle_google_login(id_token_str):
    # 1. 토큰 검증
    idinfo = verify_google_token(id_token_str)
    if not idinfo:
        raise Exception("유효하지 않은 Google ID Token입니다.")

    # 2. 유저 정보 추출
    google_id = idinfo['sub']
    email = idinfo['email']
    name = idinfo.get('name', '')
    photo_url = idinfo.get('picture', '')

    # 3. 이미 있는 유저인지 확인
    user = User.query.filter_by(google_id=google_id).first()

    # 4. 없으면 새로 생성
    if not user:
        user = User(
            google_id=google_id,
            email=email,
            name=name,
            photo_url=photo_url
        )
        db.session.add(user)
        db.session.commit()

    # 5. JWT 토큰 생성 (config 값 사용)
    payload = {
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
    }
    token = jwt.encode(payload, current_app.config["JWT_SECRET_KEY"], algorithm='HS256')

    return user, token
