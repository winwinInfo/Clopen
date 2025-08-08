from flask import Blueprint, jsonify

health_bp = Blueprint('health', __name__)

@health_bp.route('/health')
def health_check():
    """서버 상태 확인"""
    return jsonify({
        "status": "OK", 
        "message": "서버가 잘 돌아가고 있어요!"
    })