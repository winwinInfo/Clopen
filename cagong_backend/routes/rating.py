from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity, verify_jwt_in_request
from services.rating_service import RatingService

rating_bp = Blueprint('ratings', __name__)


@rating_bp.route('/<int:cafe_id>', methods=['GET'])
def get_rating_stats(cafe_id):
    """
    카페 평점 통계 조회
    ---
    tags:
      - Ratings
    summary: 카페의 평점 통계를 조회합니다.
    description: 평균 평점, 평가 인원 수, 평점 분포를 조회합니다. 로그인 시 내 평점도 포함됩니다.
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 평점을 조회할 카페 ID
        schema:
          type: integer
    security:
      - BearerAuth: []
    responses:
      200:
        description: 평점 정보 조회 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "평점 정보를 조회했습니다."
              data:
                average_rating: 4.2
                total_count: 15
                my_rating: 5
                rating_distribution:
                  "1": 0
                  "2": 1
                  "3": 2
                  "4": 5
                  "5": 7
    """
    user_id = None
    try:
        verify_jwt_in_request(optional=True)
        user_id = get_jwt_identity()
    except:
        pass

    return RatingService.get_rating_stats(cafe_id, user_id)


@rating_bp.route('/<int:cafe_id>', methods=['POST'])
@jwt_required()
def upsert_rating(cafe_id):
    """
    평점 등록/수정
    ---
    tags:
      - Ratings
    summary: 카페에 평점을 등록하거나 수정합니다.
    description: 기존 평점이 있으면 수정, 없으면 신규 등록합니다.
    security:
      - BearerAuth: []
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 평점을 등록할 카페 ID
        schema:
          type: integer
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            rate:
              type: integer
              example: 5
    responses:
      201:
        description: 평점 등록 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "평점이 등록되었습니다."
              data:
                id: 123
                user_id: 45
                cafe_id: 10
                rate: 5
                created_at: "2025-12-31T10:00:00"
                updated_at: "2025-12-31T10:00:00"
      200:
        description: 평점 수정 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "평점이 수정되었습니다."
    """
    user_id = get_jwt_identity()
    data = request.get_json()
    return RatingService.upsert_rating(user_id, cafe_id, data)


@rating_bp.route('/<int:cafe_id>', methods=['DELETE'])
@jwt_required()
def delete_rating(cafe_id):
    """
    평점 삭제
    ---
    tags:
      - Ratings
    summary: 내가 등록한 평점을 삭제합니다.
    security:
      - BearerAuth: []
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 평점을 삭제할 카페 ID
        schema:
          type: integer
    responses:
      200:
        description: 평점 삭제 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "평점이 삭제되었습니다."
              data: null
    """
    user_id = get_jwt_identity()
    return RatingService.delete_rating(user_id, cafe_id)


@rating_bp.route('/<int:cafe_id>/my-rating', methods=['GET'])
@jwt_required()
def get_my_rating(cafe_id):
    """
    내 평점 조회
    ---
    tags:
      - Ratings
    summary: 내가 등록한 평점을 조회합니다.
    security:
      - BearerAuth: []
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 평점을 조회할 카페 ID
        schema:
          type: integer
    responses:
      200:
        description: 내 평점 조회 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "내 평점을 조회했습니다."
              data:
                rate: 5
                created_at: "2025-12-31T10:00:00"
    """
    user_id = get_jwt_identity()
    return RatingService.get_my_rating(user_id, cafe_id)


@rating_bp.route('/my-ratings', methods=['GET'])
@jwt_required()
def get_all_my_ratings():
    """
    내가 평점을 매긴 모든 카페 목록 조회
    ---
    tags:
      - Ratings
    summary: 내가 평점을 매긴 모든 카페 목록을 조회합니다.
    security:
      - BearerAuth: []
    responses:
      200:
        description: 내 평점 목록 조회 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "내가 평점을 매긴 카페 목록을 조회했습니다."
              data:
                - rating_id: 1
                  rate: 5
                  created_at: "2025-12-31T10:00:00"
                  updated_at: "2025-12-31T10:00:00"
                  cafe:
                    id: 10
                    name: "스타벅스 강남점"
                    address: "서울시 강남구 ..."
                    latitude: 37.1234
                    longitude: 127.5678
    """
    user_id = get_jwt_identity()
    return RatingService.get_all_my_ratings(user_id)
