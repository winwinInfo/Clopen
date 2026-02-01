from models import db, CafeRating, Cafe
from common.api_response import ApiResponse, ErrorCode
from sqlalchemy import func

class RatingService:

    # 다수결 키워드 변환 헬퍼
    KEYWORD_MAP = {1: "적음", 2: "보통", 3: "많음"}

    @staticmethod
    def _get_majority_keyword(distribution: dict) -> str:
        """분포에서 가장 많은 값의 키워드 반환"""
        if not distribution or all(v == 0 for v in distribution.values()):
            return None
        max_key = max(distribution, key=lambda k: distribution[k])
        return RatingService.KEYWORD_MAP.get(int(max_key))

    @staticmethod
    def get_rating_stats(cafe_id: int, user_id: int = None):
        """
        카페의 평점 통계 조회
        - average_rating: 평균 평점 (소수점 1자리)
        - total_count: 총 평가 인원 수
        - my_rating: 내가 준 평점 (로그인 시)
        - rating_distribution: 1~5점 분포
        - consent_keyword: 콘센트 다수결 키워드
        - seat_keyword: 좌석 다수결 키워드
        """

        cafe = Cafe.query.get(cafe_id)
        if not cafe:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="존재하지 않는 카페입니다.",
                http_status=404
            )

        try:
            # 카공지수 통계
            stats = db.session.query(
                func.avg(CafeRating.rate).label('average'),
                func.count(CafeRating.id).label('count')
            ).filter(
                CafeRating.cafe_id == cafe_id,
                CafeRating.rate.isnot(None)
            ).first()

            average_rating = round(float(stats.average), 1) if stats.average else 0.0
            total_count = stats.count or 0

            # 카공지수 분포 (1~5)
            distribution_query = db.session.query(
                CafeRating.rate,
                func.count(CafeRating.id)
            ).filter(
                CafeRating.cafe_id == cafe_id,
                CafeRating.rate.isnot(None)
            ).group_by(CafeRating.rate).all()

            rating_distribution = {str(i): 0 for i in range(1, 6)}
            for rate, count in distribution_query:
                if rate:
                    rating_distribution[str(rate)] = count

            # 콘센트 분포 (1~3)
            consent_query = db.session.query(
                CafeRating.consent_rate,
                func.count(CafeRating.id)
            ).filter(
                CafeRating.cafe_id == cafe_id,
                CafeRating.consent_rate.isnot(None)
            ).group_by(CafeRating.consent_rate).all()

            consent_distribution = {str(i): 0 for i in range(1, 4)}
            for rate, count in consent_query:
                if rate:
                    consent_distribution[str(rate)] = count

            # 좌석 분포 (1~3)
            seat_query = db.session.query(
                CafeRating.seat_rate,
                func.count(CafeRating.id)
            ).filter(
                CafeRating.cafe_id == cafe_id,
                CafeRating.seat_rate.isnot(None)
            ).group_by(CafeRating.seat_rate).all()

            seat_distribution = {str(i): 0 for i in range(1, 4)}
            for rate, count in seat_query:
                if rate:
                    seat_distribution[str(rate)] = count

            # 내 평점 조회
            my_rating = None
            my_consent_rate = None
            my_seat_rate = None
            if user_id:
                my_rating_obj = CafeRating.query.filter_by(
                    user_id=user_id,
                    cafe_id=cafe_id
                ).first()
                if my_rating_obj:
                    my_rating = my_rating_obj.rate
                    my_consent_rate = my_rating_obj.consent_rate
                    my_seat_rate = my_rating_obj.seat_rate

            return ApiResponse.success(
                data={
                    "average_rating": average_rating,
                    "total_count": total_count,
                    "my_rating": my_rating,
                    "my_consent_rate": my_consent_rate,
                    "my_seat_rate": my_seat_rate,
                    "rating_distribution": rating_distribution,
                    "consent_distribution": consent_distribution,
                    "seat_distribution": seat_distribution,
                    "consent_keyword": RatingService._get_majority_keyword(consent_distribution),
                    "seat_keyword": RatingService._get_majority_keyword(seat_distribution)
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
        - data에 포함된 필드만 업데이트
        - rate: 카공지수 (1~5)
        - consent_rate: 콘센트 (1=적음, 2=보통, 3=많음)
        - seat_rate: 좌석 (1=적음, 2=보통, 3=많음)
        """

        # 최소 하나의 필드는 있어야 함
        rate = data.get('rate')
        consent_rate = data.get('consent_rate')
        seat_rate = data.get('seat_rate')

        if rate is None and consent_rate is None and seat_rate is None:
            return ApiResponse.fail(
                error_code=ErrorCode.INVALID_INPUT,
                message="평점을 입력해주세요.",
                http_status=400
            )

        # 카공지수 유효성 검사 (1~5)
        if rate is not None:
            if not isinstance(rate, int) or rate < 1 or rate > 5:
                return ApiResponse.fail(
                    error_code=ErrorCode.INVALID_INPUT,
                    message="카공지수는 1~5 사이의 정수여야 합니다.",
                    http_status=400
                )

        # 콘센트 유효성 검사 (1~3)
        if consent_rate is not None:
            if not isinstance(consent_rate, int) or consent_rate < 1 or consent_rate > 3:
                return ApiResponse.fail(
                    error_code=ErrorCode.INVALID_INPUT,
                    message="콘센트 평가는 1~3 사이의 정수여야 합니다.",
                    http_status=400
                )

        # 좌석 유효성 검사 (1~3)
        if seat_rate is not None:
            if not isinstance(seat_rate, int) or seat_rate < 1 or seat_rate > 3:
                return ApiResponse.fail(
                    error_code=ErrorCode.INVALID_INPUT,
                    message="좌석 평가는 1~3 사이의 정수여야 합니다.",
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
                # 전달된 필드만 업데이트
                if rate is not None:
                    existing_rating.rate = rate
                if consent_rate is not None:
                    existing_rating.consent_rate = consent_rate
                if seat_rate is not None:
                    existing_rating.seat_rate = seat_rate
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
                    rate=rate,
                    consent_rate=consent_rate,
                    seat_rate=seat_rate
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
                    "consent_rate": rating.consent_rate,
                    "seat_rate": rating.seat_rate,
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
                        "consent_rate": rating.consent_rate,
                        "seat_rate": rating.seat_rate,
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
