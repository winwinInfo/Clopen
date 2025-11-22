from flask import current_app
from models.user import User, db
from google.oauth2 import id_token
from google.auth.transport import requests
import jwt
import datetime
from exceptions.custom_exceptions import AuthTokenException, InvalidInputException
from flask_jwt_extended import create_access_token, get_jwt_identity


#  공통: 토큰 검증 함수
def verify_google_token(id_token_str):
    try:
        idinfo = id_token.verify_oauth2_token(
            id_token_str,
            requests.Request(),
            current_app.config.get("GOOGLE_CLIENT_ID")
        )
        return idinfo
    except ValueError:
        return None


# 공통: JWT 생성 헬퍼 함수 (중복 제거)
# def _generate_jwt(user_id):
#     payload = {
#         'sub': user_id,
#         'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
#     }
#     return jwt.encode(payload, current_app.config["JWT_SECRET_KEY"], algorithm='HS256')


# -기능 1: 로그인 (가입 여부 확인)
def login_with_google(id_token_str):
    """
    기존 회원이면 -> User 객체와 Token 반환
    신규 회원이면 -> None, None 반환 (컨트롤러에서 회원가입 유도)
    """
    # 1. 토큰 검증
    idinfo = verify_google_token(id_token_str)
    if not idinfo:
        raise AuthTokenException("유효하지 않은 Google ID Token입니다.")

    # 2. 유저 조회
    google_id = idinfo['sub']
    user = User.query.filter_by(google_id=google_id).first()

    # 3. 분기 처리
    if user:
        # 이미 가입된 유저 -> 토큰 발급
        token = create_access_token(identity=user.id)
        return user, token
    else:
        # 신규 유저 -> None 반환 (컨트롤러가 is_new_user=True 응답을 보내도록 유도)
        return None, None


# 회원가입 (닉네임 포함 저장)
def register_with_google(id_token_str, nickname):
    """
    신규 회원가입: Google 정보 + 닉네임 저장
    """
    # 1. 토큰 재검증 (보안 필수)
    idinfo = verify_google_token(id_token_str)
    if not idinfo:
        raise AuthTokenException("유효하지 않은 Google ID Token입니다.")

    # 2. 닉네임 중복 검사
    if User.query.filter_by(nickname=nickname).first():
        raise InvalidInputException("이미 사용 중인 닉네임입니다.")

    # 3. 이미 가입된 Google ID인지 재확인 (방어 로직)
    google_id = idinfo['sub']
    if User.query.filter_by(google_id=google_id).first():
        raise InvalidInputException("이미 가입된 구글 계정입니다.")

    # 4. 유저 생성 (닉네임 포함)
    new_user = User(
        google_id=google_id,
        email=idinfo['email'],
        name=idinfo.get('name', ''),
        photo_url=idinfo.get('picture', ''),
        nickname=nickname,
        role='user',
        provider='google'
    )

    db.session.add(new_user)
    db.session.commit()

    # 5. 가입 완료 후 토큰 발급
    token = create_access_token(identity=new_user.id)

    return new_user, token

## 회원 탈퇴 처리 (소프트 삭제)
def delete_user_account():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)

    if not user:
        raise InvalidInputException("사용자를 찾을 수 없습니다.")

    user.google_id = f"deleted_{user_id}"
    user.email = f"deleted_{user_id}@deleted.com"
    user.nickname = f"deleted_{user_id}"
    user.name = "deleted_user"
    user.photo_url = None

    db.session.commit()
    return True