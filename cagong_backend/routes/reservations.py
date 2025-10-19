# routes/reservations.py

from flask import Blueprint, jsonify, request
from services import reservation_service


reservation_bp = Blueprint('reservations', __name__)


@reservation_bp.route('/availability', methods=['GET'])
def check_availability():
    """
    예약 가능 여부 확인

    Query Parameters:
        cafe_id: 카페 ID (required)
        date: 날짜 YYYY-MM-DD (required)
        time: 시간 HH:MM (required)
        duration: 예약 시간 (시간 단위, default: 2)

    Example:
        GET /reservations/availability?cafe_id=123&date=2025-10-19&time=14:00&duration=2
    """
    try:
        # Query Parameters 가져오기
        cafe_id = request.args.get('cafe_id', type=int)
        date_str = request.args.get('date')
        time_str = request.args.get('time')
        duration = request.args.get('duration', default=2, type=int)

        # 필수 파라미터 검증
        if not cafe_id:
            return jsonify({
                "success": False,
                "error": "cafe_id는 필수 파라미터입니다."
            }), 400

        if not date_str:
            return jsonify({
                "success": False,
                "error": "date는 필수 파라미터입니다. (형식: YYYY-MM-DD)"
            }), 400

        if not time_str:
            return jsonify({
                "success": False,
                "error": "time은 필수 파라미터입니다. (형식: HH:MM)"
            }), 400

        # Service 호출
        result = reservation_service.check_availability(
            cafe_id=cafe_id,
            date_str=date_str,
            time_str=time_str,
            duration_hours=duration
        )

        # 카페를 찾을 수 없는 경우
        if result is None:
            return jsonify({
                "success": False,
                "error": f"ID {cafe_id} 카페를 찾을 수 없습니다."
            }), 404

        # 에러가 있는 경우
        if "error" in result:
            return jsonify({
                "success": False,
                "error": result["error"]
            }), 400

        # 성공
        return jsonify({
            "success": True,
            "data": result
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500


@reservation_bp.route('/slots', methods=['GET'])
def get_available_slots():
    """
    특정 날짜의 모든 타임 슬롯 조회

    Query Parameters:
        cafe_id: 카페 ID (required)
        date: 날짜 YYYY-MM-DD (required)

    Example:
        GET /reservations/slots?cafe_id=123&date=2025-10-19
    """
    try:
        # Query Parameters 가져오기
        cafe_id = request.args.get('cafe_id', type=int)
        date_str = request.args.get('date')

        # 필수 파라미터 검증
        if not cafe_id:
            return jsonify({
                "success": False,
                "error": "cafe_id는 필수 파라미터입니다."
            }), 400

        if not date_str:
            return jsonify({
                "success": False,
                "error": "date는 필수 파라미터입니다. (형식: YYYY-MM-DD)"
            }), 400

        # Service 호출
        result = reservation_service.get_available_slots(
            cafe_id=cafe_id,
            date_str=date_str
        )

        # 카페를 찾을 수 없는 경우
        if result is None:
            return jsonify({
                "success": False,
                "error": f"ID {cafe_id} 카페를 찾을 수 없습니다."
            }), 404

        # 에러가 있는 경우
        if "error" in result:
            return jsonify({
                "success": False,
                "error": result["error"]
            }), 400

        # 예약 시스템 비활성화된 경우
        if not result.get("reservation_enabled", True):
            return jsonify({
                "success": False,
                "message": result.get("message")
            }), 200

        # 성공
        return jsonify({
            "success": True,
            "data": result
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500
