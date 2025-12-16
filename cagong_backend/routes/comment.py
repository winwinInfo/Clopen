from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.comment_service import CommentService

comment_bp = Blueprint('comments', __name__)

@comment_bp.route('/<int:cafe_id>', methods=['GET'])
def get_comments(cafe_id):
    """
    댓글 목록 조회
    ---
    tags:
      - Comments
    summary: 특정 카페의 댓글 목록을 조회합니다.
    description: 카페에 달린 모든 댓글을 최신순으로 조회합니다.
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 댓글을 조회할 카페 ID
        schema:
          type: integer
    responses:
      200:
        description: 댓글 목록 조회 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "댓글 목록을 불러왔습니다."
              data:
                - id: 1
                  content: "분위기가 너무 좋아요!"
                  user_nickname: "카페러버"
                  user_photo: ""
                  created_at: "2023-10-25T12:00:00"
                - id: 2
                  content: "커피가 맛있어요!"
                  user_nickname: "커피매니아"
                  user_photo: null
                  created_at: "2023-10-24T10:30:00"
    """
    return CommentService.get_comments(cafe_id)


@comment_bp.route('/<int:cafe_id>', methods=['POST'])
@jwt_required()
def create_comment(cafe_id):
    """
    댓글 등록
    ---
    tags:
      - Comments
    summary: 특정 카페에 댓글을 작성합니다.
    description: 로그인한 사용자가 특정 카페에 댓글을 등록합니다.
    security:
      - BearerAuth: []
    parameters:
      - in: path
        name: cafe_id
        required: true
        description: 댓글을 작성할 카페 ID
        schema:
          type: integer
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            content:
              type: string
              example: "분위기가 너무 좋아요!"
    responses:
      201:
        description: 댓글 등록 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "댓글이 등록되었습니다."
              data:
                id: 1
                content: "분위기가 너무 좋아요!"
                user_nickname: "카페러버"
                created_at: "2023-10-25T12:00:00"
    """
    user_id = get_jwt_identity()
    data = request.get_json()
    return CommentService.create_comment(user_id, cafe_id, data)


@comment_bp.route('/<int:comment_id>', methods=['DELETE'])
@jwt_required()
def delete_comment(comment_id):
    """
    댓글 삭제
    ---
    tags:
      - Comments
    summary: 내가 쓴 댓글 삭제
    description: 본인이 작성한 댓글만 삭제할 수 있습니다.
    security:
      - BearerAuth: []
    parameters:
      - in: path
        name: comment_id
        required: true
        description: 삭제할 댓글 ID
        schema:
          type: integer
    responses:
      200:
        description: 삭제 성공
        content:
          application/json:
            example:
              status: SUCCESS
              message: "댓글이 삭제되었습니다."
      403:
        description: 권한 없음 (내 댓글 아님)
        content:
          application/json:
            example:
              status: FAIL
              message: "본인의 댓글만 삭제할 수 있습니다."
    """
    user_id = get_jwt_identity()
    return CommentService.delete_comment(user_id, comment_id)


