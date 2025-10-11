
from models import db, Cafe

def get_all_cafes():
    """모든 카페 목록을 데이터베이스에서 조회"""
    # 리스트로 반환
    return Cafe.query.all()

def get_cafe_by_id(cafe_id):
    """특정 ID의 카페를 데이터베이스에서 조회"""
    # 결과가 없으면 None을 반환
    return Cafe.query.get(cafe_id)