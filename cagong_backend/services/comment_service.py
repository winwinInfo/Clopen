from models import db, Comment, Cafe, User
from common.api_response import ApiResponse, ErrorCode

class CommentService:

    @staticmethod
    def create_comment(user_id: int, cafe_id: int, data: dict):
        # 1. 입력값 검증
        content = data.get('content')
        if not content:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="댓글 내용을 입력해주세요.",
                http_status=400
            )

        # 2. Cafe 존재 여부 확인
        cafe = Cafe.query.get(cafe_id)
        if not cafe:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT, # 기존 코드 스타일 따름 (404)
                message="존재하지 않는 카페입니다.",
                http_status=404
            )

        try:
            # 3. 댓글 생성 및 저장
            new_comment = Comment(
                user_id=user_id,
                cafe_id=cafe_id,
                content=content,
            )
            db.session.add(new_comment)
            db.session.commit()

            return ApiResponse.success(
                data=new_comment.to_dict(),
                message="댓글이 등록되었습니다.",
                http_status=201
            )

        except Exception:
            db.session.rollback()
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="댓글 등록 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )

    @staticmethod
    def delete_comment(user_id: int, comment_id: int):
        # 1. 댓글 조회
        comment = Comment.query.get(comment_id)

        if not comment:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT, # 리소스 없음
                message="존재하지 않는 댓글입니다.",
                http_status=404
            )

        # 2. 권한 확인 (본인 댓글인지)
        # DB의 user_id(int)와 JWT의 user_id(int/str) 비교
        if str(comment.user_id) != str(user_id):
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT, # 혹은 ErrorCode.FORBIDDEN 권장
                message="본인의 댓글만 삭제할 수 있습니다.",
                http_status=403
            )

        try:
            # 3. 삭제 진행
            db.session.delete(comment)
            db.session.commit()

            return ApiResponse.success(
                data=None, # 삭제는 데이터 반환 불필요 시 None
                message="댓글이 삭제되었습니다.",
                http_status=200
            )

        except Exception:
            db.session.rollback()
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="댓글 삭제 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )