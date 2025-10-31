from flask import Blueprint, request, jsonify
from services import auth_service
from common.api_response import ApiResponse
from exceptions.custom_exceptions import InvalidInputException

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    # --- 1. try...except 제거 ---
    # 예외가 발생하면 handlers.py가 알아서 처리합니다.

    data = request.get_json()

    # 2. JSON 바디 자체가 없는 경우 (request.get_json()이 None 반환)
    if data is None:
        raise InvalidInputException("요청 본문(body)이 JSON 형식이 아니거나 비어있습니다.")

    id_token = data.get('idToken')

    # 3. idToken이 없는 경우
    if not id_token:
        raise InvalidInputException("idToken 필드는 필수입니다.")

    # 4. 서비스 호출
    # 여기서 AuthTokenException 등이 터지면
    # handlers.py가 알아서 401 응답을 보냅니다.
    user, token = auth_service.handle_google_login(id_token)

    # 5. 성공 시 (예외가 안 터진 경우)
    # ApiResponse.success를 사용해 200 응답
    user_dto = {
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'created_at': user.created_at.isoformat()
    }

    return ApiResponse.success(
        data={'user': user_dto, 'token': token},
        message="Google 로그인 성공"
    )
