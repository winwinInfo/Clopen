# routes/cafes.py

from flask import Blueprint, jsonify, request
from services import cafe_service


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




@cafe_bp.route('/')
def Is_reservation_possible_cafe(cafe_id):
    """
    예약 가능한 카페인지 true/false 반환
    """
    pass 