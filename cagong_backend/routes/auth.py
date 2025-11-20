from flask import Blueprint, request
from flask_jwt_extended import jwt_required

from services import auth_service
from common.api_response import ApiResponse
from exceptions.custom_exceptions import InvalidInputException

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

# 1. 로그인 요청 (기존 /google-login)
@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    """
    Google 로그인
    ---
    tags:
      - Auth
    summary: Google Login
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required:
            - idToken
          properties:
            idToken:
              type: string
              example: "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
    responses:
      200:
        description: 로그인 성공 또는 신규 회원 여부 반환
      400:
        description: 잘못된 요청
    """
    data = request.get_json()
    id_token = data.get('idToken')

    if not id_token:
        raise InvalidInputException("idToken은 필수입니다.")

    user, token = auth_service.login_with_google(id_token)

    if user is None:
        return ApiResponse.success(
            data={'is_new_user': True},
            message="신규 회원입니다. 닉네임을 입력하여 회원가입을 진행해주세요."
        )

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
    """
    Google 회원가입
    ---
    tags:
      - Auth
    summary: Google Signup
    consumes:
      - application/json
    parameters:
      - in: body
        name: body
        schema:
          type: object
          required:
            - idToken
            - nickname
          properties:
            idToken:
              type: string
              example: "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
            nickname:
              type: string

    responses:
      200:
        description: 회원가입 및 로그인 성공
      400:
        description: 잘못된 요청
    """
    data = request.get_json()
    id_token = data.get('idToken')
    nickname = data.get('nickname')

    if not id_token or not nickname:
        raise InvalidInputException("idToken과 nickname은 필수입니다.")

    user, token = auth_service.register_with_google(id_token, nickname)

    return ApiResponse.success(
        data={
            'user': user.to_dict(),
            'token': token,
            'is_new_user': False
        },
        message="회원가입 및 로그인 성공"
    )



@auth_bp.route("/delete", methods=["DELETE"])
@jwt_required()
def delete_user():
    """
    회원 탈퇴
    ---
    tags:
      - Auth
    summary: 회원 탈퇴
    security:
      - BearerAuth: []
    responses:
      200:
        description: 성공적으로 탈퇴됨
      401:
        description: 인증 실패
      404:
        description: 사용자를 찾을 수 없음
    """
    auth_service.delete_user_account()
    return ApiResponse.success(
        message="계정이 성공적으로 삭제되었습니다.",
        data=None,
        http_status=200
    )
