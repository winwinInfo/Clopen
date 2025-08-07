from flask import Blueprint, request, jsonify
from services import auth_service

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    try:
        # 클라이언트에서 보낸 idToken 추출
        data = request.get_json()
        id_token = data.get('idToken')

        if not id_token:
            return jsonify({'error': 'idToken이 필요합니다'}), 400

        # 토큰 검증 및 유저 정보 가져오기
        user, token = auth_service.handle_google_login(id_token)

        return jsonify({
            'user': {
                'id': user.id,
                'email': user.email,
                'name': user.name,
                'role': user.role,
                'created_at': user.created_at.isoformat()
            },
            'token': token
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500
