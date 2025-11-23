# routes/reservations.py

from flask import Blueprint, jsonify, request
from services import reservation_service


reservation_bp = Blueprint('reservations', __name__)






@reservation_bp.route('/availability', methods=['GET'])
def check_availability():
    """
    예약 가능 여부 확인
    ---
    tags:
      - Reservation
    parameters:
      - name: cafe_id
        in: query
        type: integer
        required: true
        description: "카페 ID"
      - name: date
        in: query
        type: string
        required: true
        description: "날짜 YYYY-MM-DD"
      - name: time
        in: query
        type: string
        required: true
        description: "시간 HH:MM"
      - name: duration
        in: query
        type: integer
        required: false
        default: 2
        description: "예약 시간 (1시간 단위)"
    responses:
      200:
        description: "예약 가능 여부 확인 성공"
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            data:
              type: object
              properties:
                available:
                  type: boolean
                  description: "예약 가능 여부"
                cafe_id:
                  type: integer
                  description: "카페 ID"
                date:
                  type: string
                  description: "요청한 날짜"
                time:
                  type: string
                  description: "요청한 시간"
                duration:
                  type: integer
                  description: "예약 시간 (시간 단위)"
      400:
        description: "잘못된 요청"
      404:
        description: "카페를 찾을 수 없음"
      500:
        description: "서버 오류"
    """
    try:
        # Query Parameters 가져오기
        cafe_id    = request.args.get('cafe_id', type=int)
        date_str   = request.args.get('date')
        time_str   = request.args.get('time')
        duration   = request.args.get('duration', default=2, type=int)

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


@reservation_bp.route('/', methods=['POST'])
def create_reservation():
    """
    예약 생성
    ---
    tags:
      - Reservation
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - cafe_id
            - user_id
            - date
            - time
            - duration
          properties:
            cafe_id:
              type: integer
              description: "카페 ID"
            user_id:
              type: integer
              description: "사용자 ID"
            date:
              type: string
              description: "날짜 YYYY-MM-DD"
            time:
              type: string
              description: "시간 HH:MM"
            duration:
              type: integer
              description: "예약 시간 (1시간 단위)"
            seat_count:
              type: integer
              default: 1
              description: "예약 좌석 수"
    responses:
      201:
        description: "예약 생성 성공"
      400:
        description: "잘못된 요청"
      404:
        description: "카페를 찾을 수 없음"
      500:
        description: "서버 오류"
    """
    try:
        # JSON Body 가져오기
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "요청 본문이 비어있습니다."
            }), 400

        cafe_id = data.get('cafe_id')
        user_id = data.get('user_id')
        date_str = data.get('date')
        time_str = data.get('time')
        duration = data.get('duration')
        seat_count = data.get('seat_count', 1)

        # 필수 파라미터 검증
        if not cafe_id:
            return jsonify({
                "success": False,
                "error": "cafe_id는 필수 파라미터입니다."
            }), 400

        if not user_id:
            return jsonify({
                "success": False,
                "error": "user_id는 필수 파라미터입니다."
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

        if not duration:
            return jsonify({
                "success": False,
                "error": "duration은 필수 파라미터입니다."
            }), 400

        # Service 호출
        result = reservation_service.create_reservation(
            cafe_id=cafe_id,
            user_id=user_id,
            date_str=date_str,
            time_str=time_str,
            duration_hours=duration,
            seat_count=seat_count
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

        # 예약 불가능한 경우
        if result.get("success") == False:
            return jsonify({
                "success": False,
                "message": result.get("message")
            }), 400

        # 성공
        return jsonify({
            "success": True,
            "data": result
        }), 201

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500
















