from flask import Blueprint, request
from services import auth_service
from common.api_response import ApiResponse
from exceptions.custom_exceptions import InvalidInputException

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

# 1. 로그인 요청 (기존 /google-login)
@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    data = request.get_json()
    id_token = data.get('idToken')

    if not id_token:
        raise InvalidInputException("idToken은 필수입니다.")

    # 서비스 호출
    user, token = auth_service.login_with_google(id_token)

    # user가 없으면 신규 회원임
    if user is None:
        return ApiResponse.success(
            data={'is_new_user': True},
            message="신규 회원입니다. 닉네임을 입력하여 회원가입을 진행해주세요."
        )

    # 기존 회원이면 로그인 성공
    return ApiResponse.success(
        data={
            'user': user.to_dict(),
            'token': token,
            'is_new_user': False
        },
        message="Google 로그인 성공"
    )

# 2. 회원가입 요청 (신규 /google-signup)
@auth_bp.route('/google-signup', methods=['POST'])
def google_signup():
    data = request.get_json()
    id_token = data.get('idToken')
    nickname = data.get('nickname') # 닉네임 필수

    if not id_token or not nickname:
        raise InvalidInputException("idToken과 nickname은 필수입니다.")

    # 회원가입 서비스 호출
    user, token = auth_service.register_with_google(id_token, nickname)

    return ApiResponse.success(
        data={
            'user': user.to_dict(),
            'token': token,
            'is_new_user': False # 이제 가입되었으니 False
        },
        message="회원가입 및 로그인 성공"
    )