# migrate_data.py

import json
from app import app
from models import db, Cafe
from datetime import datetime


######################################################################
######################################################################
##########    json -> sqlite 데이터 migrate용 스크립트(일회용)    ##########
######################################################################
######################################################################


def parse_time_string(time_str):
    """
    시간 문자열을 파싱해서 HH:MM 형식의 문자열로 반환
    예: "09:00~22:00" -> ("09:00", "22:00")
    예: "휴무" or None -> (None, None)
    """
    if not time_str or time_str == "휴무":
        return None, None

    try:
        # "09:00~22:00" 형태 파싱 (공백 제거)
        if '~' in time_str:
            start, end = time_str.split('~')
            start = start.strip()
            end = end.strip()

            # 24:00을 23:59로 변환 (24:00은 자정을 의미하지만 표준 시간 형식이 아님)
            if end == "24:00":
                end = "23:59"
            if start == "24:00":
                start = "23:59"

            return start, end
    except Exception as e:
        print(f"  시간 파싱 실패: {time_str} - {e}")
        return None, None

    return None, None


def calculate_total_seats(cafe_data):
    """좌석 수 계산"""
    total = 0
    for i in range(1, 6):
        count = cafe_data.get(f'Seating Count {i}')
        if count:
            total += int(count)
    return total


def calculate_total_consents(cafe_data):
    """콘센트 수 계산"""
    total = 0
    for i in range(1, 6):
        power = cafe_data.get(f'Power Count {i}')
        if power and power != "0":
            try:
                total += int(power)
            except ValueError:
                pass
    return total


def migrate():
    with app.app_context():
        print("데이터 이전을 시작합니다...")

        # 기존 데이터 모두 삭제
        print("기존 데이터를 삭제합니다...")
        try:
            db.session.query(Cafe).delete()
            db.session.commit()
            print("기존 데이터 삭제 완료!")
        except Exception as e:
            db.session.rollback()
            print(f"기존 데이터 삭제 중 오류: {e}")
            return

        try:
            with open('cafe_info.json', 'r', encoding='utf-8') as f:
                cafe_data_list = json.load(f)
        except FileNotFoundError:
            print(f"오류: 'cafe_info.json' 파일을 찾을 수 없습니다. 파일 경로를 확인해주세요.")
            return
        except json.JSONDecodeError:
            print(f"오류: 'cafe_info.json' 파일이 유효한 JSON 형식이 아닙니다.")
            return

        success_count = 0
        fail_count = 0
        seen_ids = set()  # 중복 ID 체크용

        for cafe_data in cafe_data_list:
            cafe_id = int(cafe_data.get('ID')) if cafe_data.get('ID') is not None else None
            cafe_name = cafe_data.get('Name')
            cafe_address = cafe_data.get('Address')

            # 필수 필드 확인
            if cafe_id is None:
                print(f"경고: 'ID'가 없는 카페 데이터를 건너뜁니다: {cafe_name if cafe_name else 'Unknown Cafe'}")
                fail_count += 1
                continue
            if cafe_name is None:
                print(f"경고: ID {cafe_id} 카페에 'Name'이 없습니다. 해당 데이터를 건너뜁니다.")
                fail_count += 1
                continue
            if cafe_address is None:
                print(f"경고: ID {cafe_id} ({cafe_name}) 카페에 'Address'가 없습니다. 해당 데이터를 건너뜁니다.")
                fail_count += 1
                continue

            # 중복 ID 체크
            if cafe_id in seen_ids:
                print(f"경고: ID {cafe_id} ({cafe_name})는 이미 추가된 ID입니다. 건너뜁니다.")
                fail_count += 1
                continue
            seen_ids.add(cafe_id)

            # 요일별 운영시간 파싱
            mon_begin, mon_end = parse_time_string(cafe_data.get('월'))
            tue_begin, tue_end = parse_time_string(cafe_data.get('화'))
            wed_begin, wed_end = parse_time_string(cafe_data.get('수'))
            thu_begin, thu_end = parse_time_string(cafe_data.get('목'))
            fri_begin, fri_end = parse_time_string(cafe_data.get('금'))
            sat_begin, sat_end = parse_time_string(cafe_data.get('토'))
            sun_begin, sun_end = parse_time_string(cafe_data.get('일'))

            # hours_weekday, hours_weekend를 Integer로 변환
            hours_weekday = cafe_data.get('Hours_weekday')
            hours_weekend = cafe_data.get('Hours_weekend')
            if hours_weekday:
                hours_weekday = int(hours_weekday)
            if hours_weekend:
                hours_weekend = int(hours_weekend)

            # 좌석 수와 콘센트 수 계산
            total_seats = calculate_total_seats(cafe_data)
            total_consents = calculate_total_consents(cafe_data)

            new_cafe = Cafe(
                id=cafe_id,
                name=cafe_name,
                address=cafe_address,
                latitude=cafe_data.get('Position (Latitude)'),
                longitude=cafe_data.get('Position (Longitude)'),
                message=cafe_data.get('Message'),
                hours_weekday=hours_weekday,
                hours_weekend=hours_weekend,
                price=cafe_data.get('Price'),
                video_url=cafe_data.get('Video URL'),
                last_order=cafe_data.get('라스트 오더'),

                # 요일별 운영시간 (begin/end로 분리)
                monday_begin=mon_begin,
                monday_end=mon_end,
                tuesday_begin=tue_begin,
                tuesday_end=tue_end,
                wednesday_begin=wed_begin,
                wednesday_end=wed_end,
                thursday_begin=thu_begin,
                thursday_end=thu_end,
                friday_begin=fri_begin,
                friday_end=fri_end,
                saturday_begin=sat_begin,
                saturday_end=sat_end,
                sunday_begin=sun_begin,
                sunday_end=sun_end,

                operating_hours=cafe_data.get('영업 시간'),

                # 예약 관련 (기본값)
                reservation_enabled=False,
                total_seats=total_seats,
                total_consents=total_consents,
            )

            db.session.add(new_cafe)
            success_count += 1
            print(f"✓ 추가: ID {new_cafe.id}, {new_cafe.name} (좌석: {total_seats}, 콘센트: {total_consents})")

        try:
            db.session.commit()
            print(f"\n{'='*60}")
            print(f"마이그레이션 완료!")
            print(f"성공: {success_count}개, 실패: {fail_count}개")
            print(f"{'='*60}")
        except Exception as e:
            db.session.rollback()
            print(f"데이터 이전 중 오류 발생 및 롤백: {e}")

if __name__ == '__main__':
    migrate()