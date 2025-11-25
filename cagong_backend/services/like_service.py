from models import db, Cafe, CafeLike, User
from common.api_response import ApiResponse, ErrorCode

class LikeService:

    @staticmethod
    def toggle_like(user_id: int, cafe_id: int):

        # Cafe 존재 여부 확인
        cafe = Cafe.query.get(cafe_id)
        if not cafe:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="존재하지 않는 카페입니다.",
                http_status=404
            )

        existing = CafeLike.query.filter_by(
            user_id=user_id,
            cafe_id=cafe_id
        ).first()

        try:
            if existing:
                db.session.delete(existing)
                cafe.likes_count = max(0, cafe.likes_count - 1)

                db.session.commit()
                return ApiResponse.success(
                    data={"liked": False},
                    message="좋아요가 취소되었습니다.",
                    http_status=200
                )

            new_like = CafeLike(user_id=user_id, cafe_id=cafe_id)
            db.session.add(new_like)

            cafe.likes_count += 1
            db.session.commit()

            return ApiResponse.success(
                data={"liked": True},
                message="좋아요가 추가되었습니다.",
                http_status=201
            )

        except Exception:
            db.session.rollback()
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="좋아요 처리 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )

    @staticmethod
    def get_liked_cafes(user_id: int):
        liked = (
            db.session.query(Cafe)
            .join(CafeLike, Cafe.id == CafeLike.cafe_id)
            .filter(CafeLike.user_id == user_id)
            .all()
        )

        cafe_list = [
            {
                "id": c.id,
                "name": c.name,
                "address": c.address,
            }
            for c in liked
        ]

        return ApiResponse.success(
            data=cafe_list,
            message="좋아요 한 카페 목록 조회 성공",
            http_status=200
        )

