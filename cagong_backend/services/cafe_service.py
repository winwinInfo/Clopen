
from models import Cafe, db



def get_all_cafes():
    """모든 카페 객체 목록을 데이터베이스에서 조회"""
    return Cafe.query.all()

def get_cafe_by_id(cafe_id):
    """특정 ID의 카페를 데이터베이스에서 조회"""
    # 결과가 없으면 None을 반환
    return Cafe.query.get(cafe_id)

def get_cafe_by_name(cafe_name):
    """이름으로 카페를 데이터베이스에서 조회"""
    # 이름이 정확히 일치하는 첫 번째 카페를 반환 (없으면 None)
    return Cafe.query.filter_by(name=cafe_name).first()



def get_all_reservable_cafes():
    """ 예약 가능한 모든 카페"""
    return Cafe.query.filter_by(reservation_enabled=True).all()

def get_all_cafes_names():
    """모든 카페 이름 리스트를 반환"""
    result = Cafe.query.with_entities(Cafe.name).all()
    return [name for (name,) in result]

def get_all_cafes_ids():
    """모든 카페 ID 리스트를 반환"""
    result = Cafe.query.with_entities(Cafe.id).all()
    return [cafe_id for (cafe_id,) in result]


def add_cafe_from_places(name, address, latitude, longtitude):
    """
     Google Places에서 검색한 카페를 데이터베이스에 추가

     Args:
         name (str): 카페 이름
         address (str): 카페 주소
         latitude (float): 위도
         longitude (float): 경도

     Returns:
         tuple: (성공 여부, 결과)
             - 성공: (True, Cafe 객체)
             - 실패: (False, 에러 메시지)
    """
    # 필수 값 검증
    if not name or not address:
        return False, "카페 이름과 주소는 필수입니다."

    if latitude is None or longtitude is None:
        return False, "위도와 경도는 필수입니다."

    # 동일한 이름과 주소를 가진 카페가 이미 있는지 검사
    existing_cafe = Cafe.query.filter_by(
        name=name,
        address=address
    ).first()

    if existing_cafe:
        return False, f"'{name}' 카페가 이미 등록되어 있습니다."

    # 새로운 카페 생성
    new_cafe = Cafe(
        name        = name,
        address     = address,
        latitude    = latitude,
        longtitude  = longtitude,
        # 나머지 필드는 기본값
        # 사용자가 추가한 카페는 나중에 추가 정보를 입력할 수 있음
        reservation_enabled = False,
        total_seats     = 0,
        total_consents  = 0,
        hourly_rate     = 0,
        likes_count     = 0
    )

    # 데이터베이스에 저장
    db.session.add(new_cafe)
    db.session.commit()

    return True, new_cafe


