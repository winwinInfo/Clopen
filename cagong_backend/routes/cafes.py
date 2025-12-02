# routes/cafes.py

from flask import Blueprint, jsonify, request
from services import cafe_service
from services import places_service


cafe_bp = Blueprint('cafes', __name__)






@cafe_bp.route('/')
def get_cafe_list():
    """모든 카페 목록 조회
    ---
    tags:
      - Cafes
    responses:
      200:
        description: 카페 목록 조회 성공
      500:
        description: 서버 오류
    """
    try:
        cafes = cafe_service.get_all_cafes()

        # DB에서 받은 Cafe 객체 리스트를 JSON으로 변환
        cafe_list_dict = [cafe.to_dict() for cafe in cafes]

        return jsonify({
            "success": True,
            "count": len(cafe_list_dict),
            "data": cafe_list_dict
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500






@cafe_bp.route('/reservation-possible')
def get_all_reservable_cafe_list():
    """예약이 가능한 모든 카페 반환
    ---
    tags:
      - Cafes
    responses:
      200:
        description: 카페 목록 조회 성공
      500:
        description: 서버 오류
    """
    try:
        cafes = cafe_service.get_all_reservable_cafes()
        cafe_list_dict = [cafe.to_dict() for cafe in cafes]

        return jsonify({
            "success": True,
            "count": len(cafe_list_dict),
            "data": cafe_list_dict
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500







@cafe_bp.route('/<int:cafe_id>')
def get_cafe_by_id(cafe_id):
    """ID로 특정 카페 조회
    ---
    tags:
      - Cafes
    parameters:
      - name: cafe_id
        in: path
        type: integer
        required: true
        description: "카페 ID"
      - name: fields
        in: query
        type: string
        required: false
        description: "특정 필드만 반환 (예: id,name)"
    responses:
      200:
        description: "카페 조회 성공"
      404:
        description: "카페를 찾을 수 없음"
      500:
        description: "서버 오류"
    """
    try:
        cafe = cafe_service.get_cafe_by_id(cafe_id)

        if cafe:
            cafe_data = cafe.to_dict()

            # fields 쿼리 파라미터가 있으면 해당 필드만 반환
            fields = request.args.get('fields')
            if fields:
                requested_fields = [f.strip() for f in fields.split(',')]
                cafe_data = {k: v for k, v in cafe_data.items() if k in requested_fields}

            return jsonify({
                "success": True,
                "data": cafe_data
            })
        else:
            return jsonify({
                "success": False,
                "error": f"ID {cafe_id} 카페를 찾을 수 없습니다."
            }), 404

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500






@cafe_bp.route('/<int:cafe_id>/reservation-status')
def Is_reservation_possible_cafe(cafe_id):
    """
    카페 예약 가능 여부 조회
    카페 아이디로 해당 카페 예약 가능 여부만 반환함
    ---
    tags:
      - Cafes
    parameters:
      - name: cafe_id
        in: path
        type: integer
        required: true
        description: "카페 ID"
    responses:
      200:
        description: "예약 가능 여부 조회 성공"
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            data:
              type: object
              properties:
                is_reservation_possible:
                  type: boolean
                  example: true
                  description: "예약 가능 여부"
    """
    try:
        cafe = cafe_service.get_cafe_by_id(cafe_id)
        if cafe:
            result = {
                "is_reservation_possible": cafe.reservation_enabled
            }
            return jsonify({
                "success": True,
                "data": result
            })
        else:
            return jsonify({
                "success": False,
                "error": f"ID {cafe_id} 카페를 찾을 수 없습니다."
            }), 404
        
    except Exception as e:
        return jsonify({
                "success": False,
                "error": f"서버 오류 발생: {str(e)}"
            }), 500




@cafe_bp.route('/search', methods=['POST'])
def search_cafes_from_google_places():
    """
    Google Places API를 사용하여 카페 검색
    ---
    tags:
      - Cafes
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - query
          properties:
            query:
              type: string
              description: "검색어 (예: '스타벅스 강남', '카페')"
              example: "스타벅스 강남"
            latitude:
              type: number
              format: float
              description: "검색 중심점 위도 (선택)"
              example: 37.5665
            longitude:
              type: number
              format: float
              description: "검색 중심점 경도 (선택)"
              example: 126.9780
            radius:
              type: number
              format: float
              description: "검색 반경 (미터 단위, 선택, 기본 5000m)"
              example: 3000
    responses:
      200:
        description: "카페 검색 성공"
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            count:
              type: integer
              example: 10
            data:
              type: array
              items:
                type: object
                properties:
                  place_id:
                    type: string
                    example: "ChIJ..."
                  name:
                    type: string
                    example: "스타벅스 강남점"
                  latitude:
                    type: number
                    example: 37.5665
                  longitude:
                    type: number
                    example: 126.9780
      400:
        description: "잘못된 요청"
      500:
        description: "서버 오류"
    """
    try:
        # 요청 데이터 파싱
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "요청 본문이 비어있습니다."
            }), 400

        query = data.get('query')
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        radius = data.get('radius')

        # 검색어 필수 검증
        if not query:
            return jsonify({
                "success": False,
                "error": "검색어(query)는 필수입니다."
            }), 400

        # 위도/경도는 둘 다 있거나 둘 다 없어야 함
        if (latitude is None) != (longitude is None):
            return jsonify({
                "success": False,
                "error": "위도와 경도는 함께 제공되어야 합니다."
            }), 400

        # Places API 호출
        cafes = places_service.search_cafes_from_places(
            query=query,
            latitude=latitude,
            longitude=longitude,
            radius=radius
        )

        return jsonify({
            "success": True,
            "count": len(cafes),
            "data": cafes
        })

    except Exception as e:
        return jsonify({
            "success": False,
            "error": f"검색 중 오류 발생: {str(e)}"
        }), 500




@cafe_bp.route('/add-from-places', methods=['POST'])
def add_cafe_from_places():
    """
    Google Places에서 검색한 카페를 DB에 추가
    ---
    tags:
      - Cafes
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - name
            - address
            - latitude
            - longitude
          properties:
            name:
              type: string
              description: "카페 이름"
              example: "스타벅스 강남점"
            address:
              type: string
              description: "카페 주소"
              example: "서울 강남구 강남대로 123"
            latitude:
              type: number
              format: float
              description: "위도"
              example: 37.5665
            longitude:
              type: number
              format: float
              description: "경도"
              example: 126.9780
    responses:
      201:
        description: "카페 추가 성공"
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: true
            message:
              type: string
              example: "카페가 성공적으로 추가되었습니다."
            data:
              type: object
              description: "추가된 카페 정보"
      400:
        description: "잘못된 요청 (필수 값 누락, 중복 등)"
        schema:
          type: object
          properties:
            success:
              type: boolean
              example: false
            error:
              type: string
              example: "카페 이름과 주소는 필수입니다."
      500:
        description: "서버 오류"
    """
    try:
        # 요청 데이터 파싱
        data = request.get_json()

        if not data:
            return jsonify({
                "success": False,
                "error": "요청 본문이 비어있습니다."
            }), 400

        name = data.get('name')
        address = data.get('address')
        latitude = data.get('latitude')
        longitude = data.get('longitude')

        # cafe_service 호출 (튜플 반환: (성공 여부, 결과))
        success, result = cafe_service.add_cafe_from_places(
            name=name,
            address=address,
            latitude=latitude,
            longitude=longitude
        )

        if success:
            # 성공: result는 Cafe 객체
            cafe = result
            return jsonify({
                "success": True,
                "message": "카페가 성공적으로 추가되었습니다.",
                "data": cafe.to_dict()
            }), 201
        else:
            # 실패: result는 에러 메시지
            error_message = result
            return jsonify({
                "success": False,
                "error": error_message
            }), 400

    except Exception as e:
        # 예상치 못한 서버 오류
        return jsonify({
            "success": False,
            "error": f"서버 오류 발생: {str(e)}"
        }), 500