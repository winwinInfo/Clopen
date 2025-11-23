from models import Cafe, Reservation, db
from datetime import datetime, timedelta


# 카페마다 존재하는 Reservation 모델에서 예약 일시 정보 기반으로 시간이 겹치는 예약 레코드를 조회한다.  

def check_availability(cafe_id, date_str, time_str, duration_hours):
    """
    특정 카페의 예약 가능 여부를 확인 (실시간 계산 방식)

    Args:
        cafe_id: 카페 ID
        date_str: 날짜 문자열 (예: "2025-10-19")
        time_str: 시간 문자열 (예: "14:00")
        duration_hours: 예약 시간 (시간 단위, 예: 2)

    Returns:
        dict: 예약 가능 여부와 상세 정보
        None: 카페를 찾을 수 없는 경우
    """
    # 1. 카페 조회
    cafe = Cafe.query.get(cafe_id)
    if not cafe:
        return None

    # 2. 예약 기능 활성화 여부 확인
    if not cafe.reservation_enabled:
        return {
            "reservation_enabled": False,
            "is_available": False,
            "message": "이 카페는 예약 시스템을 운영하지 않습니다."
        }

    # 3. 날짜/시간 파싱
    try:
        request_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        request_datetime = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
    except ValueError:
        return {
            "error": "날짜 또는 시간 형식이 잘못되었습니다. (형식: YYYY-MM-DD, HH:MM)"
        }

    # 4. 과거 날짜 확인
    if request_datetime < datetime.now():
        return {
            "reservation_enabled": True,
            "is_available": False,
            "message": "과거 시간에는 예약할 수 없습니다."
        }

    # 5. 요일 확인 및 영업시간 체크
    weekday = request_date.weekday()  # 0=월, 6=일
    weekday_names = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    day_name = weekday_names[weekday]

    open_time = getattr(cafe, f"{day_name}_begin")
    close_time = getattr(cafe, f"{day_name}_end")

    # 휴무일 체크
    if not open_time or not close_time:
        return {
            "reservation_enabled": True,
            "is_available": False,
            "message": f"{date_str}은(는) 휴무일입니다."
        }

    # 영업시간 내 예약인지 확인
    end_datetime = request_datetime + timedelta(hours=duration_hours)
    end_time_str = end_datetime.strftime("%H:%M")

    if time_str < open_time or end_time_str > close_time:
        return {
            "reservation_enabled": True,
            "is_available": False,
            "message": f"영업시간({open_time}~{close_time})을 벗어났습니다.",
            "operating_hours": {
                "open": open_time,
                "close": close_time
            }
        }

    # 6. 해당 시간대에 겹치는 예약들 조회 (실시간 계산)
    overlapping_reservations = Reservation.query.filter(
        Reservation.cafe_id == cafe_id,
        Reservation.start_datetime < end_datetime,
        Reservation.end_datetime > request_datetime
    ).all()

    # 7. 30분 단위로 각 슬롯의 예약된 좌석 수 계산
    max_reserved_seats = 0
    current_time = request_datetime
    slot_count = 0

    while current_time < end_datetime:
        slot_end = current_time + timedelta(minutes=30)

        # 현재 슬롯과 겹치는 예약들의 좌석 수 합계
        reserved_in_slot = sum(
            r.seat_count for r in overlapping_reservations
            if r.start_datetime < slot_end and r.end_datetime > current_time
        )

        max_reserved_seats = max(max_reserved_seats, reserved_in_slot)
        current_time = slot_end
        slot_count += 1

    # 8. 예약 가능 좌석 수 계산
    available_seats = cafe.total_seats - max_reserved_seats

    # 9. 가격 계산 (시간당 요금 * 시간)
    total_price = cafe.hourly_rate * duration_hours

    return {
        "reservation_enabled": True,
        "is_available": available_seats > 0,
        "cafe_id": cafe_id,
        "cafe_name": cafe.name,
        "requested_date": date_str,
        "requested_time": time_str,
        "duration_hours": duration_hours,
        "available_seats": available_seats,
        "total_seats": cafe.total_seats,
        "reserved_seats": max_reserved_seats,
        "operating_hours": {
            "open": open_time,
            "close": close_time
        },
        "hourly_rate": cafe.hourly_rate,
        "total_price": total_price,
        "message": "예약 가능합니다." if available_seats > 0 else "해당 시간대에 예약 가능한 좌석이 없습니다."
    }






def create_reservation(cafe_id, user_id, date_str, time_str, duration_hours, seat_count=1, payment_key=None):
    """
    예약 생성

    Args:
        cafe_id: 카페 ID
        user_id: 사용자 ID
        date_str: 날짜 문자열 (예: "2025-10-19")
        time_str: 시간 문자열 (예: "14:00")
        duration_hours: 예약 시간 (시간 단위, 예: 2)
        seat_count: 예약 좌석 수 (기본값: 1)
        payment_key: 토스페이먼츠 결제 키 (결제 완료 후 전달)

    Returns:
        dict: 예약 결과
        None: 카페를 찾을 수 없는 경우
    """
    # 1. 예약 가능 여부 재확인 (비동기 환경 대비)
    availability = check_availability(cafe_id, date_str, time_str, duration_hours)

    if availability is None:
        return None

    if "error" in availability:
        return availability

    if not availability.get("is_available", False):
        return {
            "success": False,
            "message": availability.get("message", "예약이 불가능합니다.")
        }

    # 2. 날짜/시간 파싱
    try:
        start_datetime = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
        end_datetime = start_datetime + timedelta(hours=duration_hours)
    except ValueError:
        return {
            "error": "날짜 또는 시간 형식이 잘못되었습니다."
        }

    # 3. 총 금액 계산
    cafe = Cafe.query.get(cafe_id)
    total_amount = cafe.hourly_rate * duration_hours

    # 4. 예약 생성
    new_reservation = Reservation(
        cafe_id=cafe_id,
        user_id=user_id,
        start_datetime=start_datetime,
        end_datetime=end_datetime,
        seat_count=seat_count,
        total_amount=total_amount,
        payment_key=payment_key,
        status='confirmed'
    )

    try:
        db.session.add(new_reservation)
        db.session.commit()

        return {
            "success": True,
            "message": "예약이 완료되었습니다.",
            "reservation": {
                "id": new_reservation.id,
                "cafe_id": cafe_id,
                "cafe_name": cafe.name,
                "user_id": user_id,
                "start_datetime": start_datetime.isoformat(),
                "end_datetime": end_datetime.isoformat(),
                "duration_hours": duration_hours,
                "seat_count": seat_count,
                "total_amount": total_amount
            }
        }
    except Exception as e:
        db.session.rollback()
        return {
            "error": f"예약 저장 중 오류가 발생했습니다: {str(e)}"
        }
