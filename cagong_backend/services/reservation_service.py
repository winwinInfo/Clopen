from models import Cafe, CafeTimeSlot, Reservation
from datetime import datetime, timedelta


def check_availability(cafe_id, date_str, time_str, duration_hours):
    """
    특정 카페의 예약 가능 여부를 확인

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

    # 6. 해당 시간의 타임 슬롯 조회 (30분 단위)
    # 예: 14:00~16:00 예약 = 14:00, 14:30, 15:00, 15:30 슬롯 필요
    required_slots = []
    current_time = request_datetime

    while current_time < end_datetime:
        slot_time_str = current_time.strftime("%H:%M")

        slot = CafeTimeSlot.query.filter_by(
            cafe_id=cafe_id,
            date=request_date,
            time_slot=slot_time_str
        ).first()

        if not slot:
            # 슬롯이 없으면 생성 필요 (초기 데이터)
            return {
                "reservation_enabled": True,
                "is_available": False,
                "message": f"해당 날짜({date_str})의 타임 슬롯이 아직 생성되지 않았습니다."
            }

        required_slots.append(slot)
        current_time += timedelta(minutes=30)

    # 7. 모든 슬롯에서 최소 가용 좌석 수 찾기
    min_available_seats = min([slot.available_seats for slot in required_slots])

    # 8. 가격 계산 (30분당 요금 * 슬롯 개수)
    slot_count = len(required_slots)
    total_price = cafe.hourly_rate * slot_count

    return {
        "reservation_enabled": True,
        "is_available": min_available_seats > 0,
        "cafe_id": cafe_id,
        "cafe_name": cafe.name,
        "requested_date": date_str,
        "requested_time": time_str,
        "duration_hours": duration_hours,
        "available_seats": min_available_seats,
        "total_seats": cafe.total_seats,
        "reserved_seats": cafe.total_seats - min_available_seats,
        "operating_hours": {
            "open": open_time,
            "close": close_time
        },
        "hourly_rate": cafe.hourly_rate,
        "total_price": total_price,
        "required_slots": slot_count,
        "message": "예약 가능합니다." if min_available_seats > 0 else "해당 시간대에 예약 가능한 좌석이 없습니다."
    }


def get_available_slots(cafe_id, date_str):
    """
    특정 카페의 특정 날짜의 모든 타임 슬롯 조회

    Args:
        cafe_id: 카페 ID
        date_str: 날짜 문자열 (예: "2025-10-19")

    Returns:
        list: 타임 슬롯 리스트
        None: 카페를 찾을 수 없는 경우
    """
    # 카페 조회
    cafe = Cafe.query.get(cafe_id)
    if not cafe:
        return None

    if not cafe.reservation_enabled:
        return {
            "reservation_enabled": False,
            "message": "이 카페는 예약 시스템을 운영하지 않습니다."
        }

    # 날짜 파싱
    try:
        target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        return {
            "error": "날짜 형식이 잘못되었습니다. (형식: YYYY-MM-DD)"
        }

    # 해당 날짜의 모든 슬롯 조회
    slots = CafeTimeSlot.query.filter_by(
        cafe_id=cafe_id,
        date=target_date
    ).order_by(CafeTimeSlot.time_slot).all()

    if not slots:
        return {
            "cafe_id": cafe_id,
            "cafe_name": cafe.name,
            "date": date_str,
            "slots": [],
            "message": f"해당 날짜({date_str})의 타임 슬롯이 아직 생성되지 않았습니다."
        }

    return {
        "cafe_id": cafe_id,
        "cafe_name": cafe.name,
        "date": date_str,
        "total_seats": cafe.total_seats,
        "slots": [slot.to_dict() for slot in slots]
    }
