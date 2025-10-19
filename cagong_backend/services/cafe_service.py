
from models import Cafe



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





def get_all_cafes_names():
    """모든 카페 이름 리스트를 반환"""
    result = Cafe.query.with_entities(Cafe.name).all()
    return [name for (name,) in result]

def get_all_cafes_ids():
    """모든 카페 ID 리스트를 반환"""
    result = Cafe.query.with_entities(Cafe.id).all()
    return [cafe_id for (cafe_id,) in result]
