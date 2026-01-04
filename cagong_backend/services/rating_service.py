from models import db, CafeRating, Cafe
from common.api_response import ApiResponse, ErrorCode
from sqlalchemy import func

class RatingService:

    @staticmethod
    def get_rating_stats(cafe_id: int, user_id: int = None):
        """
        카페의 평점 통계 조회
        - average_rating: 평균 평점 (소수점 1자리)
        - total_count: 총 평가 인원 수
        - my_rating: 내가 준 평점 (로그인 시)
        - rating_distribution: 1~5점 분포
        """

        cafe = Cafe.query.get(cafe_id)
        if not cafe:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="존재하지 않는 카페입니다.",
                http_status=404
            )

        try:
            stats = db.session.query(
                func.avg(CafeRating.rate).label('average'),
                func.count(CafeRating.id).label('count')
            ).filter(CafeRating.cafe_id == cafe_id).first()

            average_rating = round(float(stats.average), 1) if stats.average else 0.0
            total_count = stats.count or 0

            distribution_query = db.session.query(
                CafeRating.rate,
                func.count(CafeRating.id)
            ).filter(
                CafeRating.cafe_id == cafe_id
            ).group_by(CafeRating.rate).all()

            rating_distribution = {str(i): 0 for i in range(1, 6)}
            for rate, count in distribution_query:
                rating_distribution[str(rate)] = count

            my_rating = None
            if user_id:
                my_rating_obj = CafeRating.query.filter_by(
                    user_id=user_id,
                    cafe_id=cafe_id
                ).first()
                my_rating = my_rating_obj.rate if my_rating_obj else None

            return ApiResponse.success(
                data={
                    "average_rating": average_rating,
                    "total_count": total_count,
                    "my_rating": my_rating,
                    "rating_distribution": rating_distribution
                },
                message="평점 정보를 조회했습니다.",
                http_status=200
            )

        except Exception:
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="평점 조회 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )

    @staticmethod
    def upsert_rating(user_id: int, cafe_id: int, data: dict):
        """
        평점 등록 또는 수정 (Upsert)
        """

        rate = data.get('rate')
        if rate is None:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="평점을 입력해주세요.",
                http_status=400
            )

        if not isinstance(rate, int) or rate < 1 or rate > 5:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="평점은 1~5 사이의 정수여야 합니다.",
                http_status=400
            )

        cafe = Cafe.query.get(cafe_id)
        if not cafe:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="존재하지 않는 카페입니다.",
                http_status=404
            )

        try:
            existing_rating = CafeRating.query.filter_by(
                user_id=user_id,
                cafe_id=cafe_id
            ).first()

            if existing_rating:
                existing_rating.rate = rate
                db.session.commit()

                return ApiResponse.success(
                    data=existing_rating.to_dict(),
                    message="평점이 수정되었습니다.",
                    http_status=200
                )
            else:
                new_rating = CafeRating(
                    user_id=user_id,
                    cafe_id=cafe_id,
                    rate=rate
                )
                db.session.add(new_rating)
                db.session.commit()

                return ApiResponse.success(
                    data=new_rating.to_dict(),
                    message="평점이 등록되었습니다.",
                    http_status=201
                )

        except Exception:
            db.session.rollback()
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="평점 등록 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )

    @staticmethod
    def delete_rating(user_id: int, cafe_id: int):
        """
        내 평점 삭제
        """

        rating = CafeRating.query.filter_by(
            user_id=user_id,
            cafe_id=cafe_id
        ).first()

        if not rating:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="등록된 평점이 없습니다.",
                http_status=404
            )

        try:
            db.session.delete(rating)
            db.session.commit()

            return ApiResponse.success(
                data=None,
                message="평점이 삭제되었습니다.",
                http_status=200
            )

        except Exception:
            db.session.rollback()
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="평점 삭제 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )

    @staticmethod
    def get_my_rating(user_id: int, cafe_id: int):
        """
        내가 준 평점 조회
        """

        rating = CafeRating.query.filter_by(
            user_id=user_id,
            cafe_id=cafe_id
        ).first()

        if rating:
            return ApiResponse.success(
                data={
                    "rate": rating.rate,
                    "created_at": rating.created_at.isoformat()
                },
                message="내 평점을 조회했습니다.",
                http_status=200
            )
        else:
            return ApiResponse.success(
                data=None,
                message="평점을 아직 등록하지 않았습니다.",
                http_status=200
            )

    @staticmethod
    def get_all_my_ratings(user_id: int):
        """
        내가 평점을 매긴 모든 카페 목록 조회
        """
        try:
            ratings = CafeRating.query.filter_by(user_id=user_id).all()

            if not ratings:
                return ApiResponse.success(
                    data=[],
                    message="평점을 매긴 카페가 없습니다.",
                    http_status=200
                )

            result = []
            for rating in ratings:
                cafe = Cafe.query.get(rating.cafe_id)
                if cafe:
                    result.append({
                        "rating_id": rating.id,
                        "rate": rating.rate,
                        "created_at": rating.created_at.isoformat(),
                        "updated_at": rating.updated_at.isoformat(),
                        "cafe": {
                            "id": cafe.id,
                            "name": cafe.name,
                            "address": cafe.address
                        }
                    })

            return ApiResponse.success(
                data=result,
                message="내가 평점을 매긴 카페 목록을 조회했습니다.",
                http_status=200
            )

        except Exception:
            return ApiResponse.fail(
                error_code=ErrorCode.DATABASE_ERROR,
                message="평점 목록 조회 중 데이터베이스 오류가 발생했습니다.",
                http_status=500
            )
