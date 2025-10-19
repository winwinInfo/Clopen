from . import db
from datetime import datetime


class CafeTimeSlot(db.Model):
    """카페의 시간대별 좌석 상태 관리"""
    __tablename__ = 'cafe_time_slots'

    id = db.Column(db.Integer, primary_key=True)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.id'), nullable=False)

    # 날짜와 시간 (30분 단위 슬롯)
    date = db.Column(db.Date, nullable=False)           # 2025-10-19
    time_slot = db.Column(db.String(5), nullable=False) # "09:00", "09:30", "10:00", ...

    # 좌석 정보
    total_seats = db.Column(db.Integer, nullable=False)      # 해당 카페의 총 좌석 수
    available_seats = db.Column(db.Integer, nullable=False)  # 현재 예약 가능한 좌석 수
    reserved_seats = db.Column(db.Integer, default=0)        # 현재 예약된 좌석 수

    # 타임스탬프
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 복합 유니크 제약: 같은 카페의 같은 날짜/시간은 하나만 존재
    __table_args__ = (
        db.UniqueConstraint('cafe_id', 'date', 'time_slot', name='uq_cafe_date_time'),
    )



    # repr은 디버깅용 함수
    def __repr__(self):
        return f'<CafeTimeSlot cafe_id={self.cafe_id} {self.date} {self.time_slot} ({self.available_seats}/{self.total_seats})>'

    def to_dict(self):
        """JSON 응답을 위한 딕셔너리 변환"""
        return {
            'id': self.id,
            'cafe_id': self.cafe_id,
            'date': self.date.isoformat() if self.date else None,
            'time_slot': self.time_slot,
            'total_seats': self.total_seats,
            'available_seats': self.available_seats,
            'reserved_seats': self.reserved_seats,
            'is_available': self.available_seats > 0,
            'occupancy_rate': round((self.reserved_seats / self.total_seats * 100), 1) if self.total_seats > 0 else 0
        }
