# routes/cafes.py

from flask import Blueprint, jsonify
from services import cafe_service


cafe_bp = Blueprint('cafes', __name__)


@cafe_bp.route('/')
def get_cafe_list():
    """모든 카페 목록 조회 (전체 정보)"""
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
    """ID로 특정 카페 조회 (전체 정보)"""
    try:
        cafe = cafe_service.get_cafe_by_id(cafe_id)

        if cafe:
            return jsonify({
                "success": True,
                "data": cafe.to_dict()
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





@cafe_bp.route('/<int:cafe_id>/name')
def get_name_by_id(cafe_id):
    """ID로 카페 이름 조회"""
    try:
        cafe = cafe_service.get_cafe_by_id(cafe_id)


        if cafe:
            return jsonify({
                "success": True,
                "data": {
                    "id": cafe.id,
                    "name": cafe.name
                }
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
