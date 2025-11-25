from flask import Blueprint
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.like_service import LikeService

likes_bp = Blueprint('likes', __name__)

@likes_bp.route('/<int:cafe_id>/like', methods=['POST'])
@jwt_required()
def toggle_like(cafe_id):
    """
        좋아요 토글
        ---
        tags:
          - Likes
        summary: 카페 좋아요 또는 취소
        description: 특정 카페에 대해 좋아요를 추가하거나 취소합니다.
        security:
          - BearerAuth: []

        parameters:
          - in: path
            name: cafe_id
            required: true
            description: 좋아요를 추가/취소할 카페의 ID
            schema:
              type: integer
              example: 12

        responses:
          200:
            description: 좋아요 취소됨
            content:
              application/json:
                example:
                  status: SUCCESS
                  message: "좋아요가 취소되었습니다."
                  data:
                    liked: false
          201:
            description: 좋아요 추가됨
            content:
              application/json:
                example:
                  status: SUCCESS
                  message: "좋아요가 추가되었습니다."
                  data:
                    liked: true
    """
    user_id = get_jwt_identity()
    return LikeService.toggle_like(user_id, cafe_id)


@likes_bp.route('/me', methods=['GET'])
@jwt_required()
def my_liked_cafes():
    """
    내가 좋아요한 카페 목록 조회
    ---
    tags:
      - Likes
    summary: 내가 좋아요한 카페 목록을 조회합니다.
    security:
      - BearerAuth: []
    responses:
      200:
        description: 성공
        schema:
          type: object
          properties:
            status:
              type: string
            message:
              type: string
            data:
              type: array
              items:
                type: object
                properties:
                  id:
                    type: integer
                  name:
                    type: string
                  address:
                    type: string
        examples:
          application/json:
            status: "SUCCESS"
            message: "좋아요한 카페 목록 조회 성공"
            data:
              - id: 1
                name: "카페 어울림"
                address: "서울시 강남구..."
              - id: 3
                name: "카페 모노"
                address: "서초대로 ..."
    """
    user_id = get_jwt_identity()
    return LikeService.get_liked_cafes(user_id)
