from . import db
from datetime import datetime


class Cafe(db.Model):
    __tablename__ = 'cafes'
    
    # 기본 정보
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.Text, nullable=False)
    
    # 위치 정보
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    
    # 운영 정보
    message = db.Column(db.Text)
    hours_weekday = db.Column(db.Float)  # 권장 이용 시간
    hours_weekend = db.Column(db.Float)
    price = db.Column(db.String(50))
    video_url = db.Column(db.String(255))
    last_order = db.Column(db.String(50))
    
    # 요일별 운영시간
    monday = db.Column(db.String(50))
    tuesday = db.Column(db.String(50))
    wednesday = db.Column(db.String(50))
    thursday = db.Column(db.String(50))
    friday = db.Column(db.String(50))
    saturday = db.Column(db.String(50))
    sunday = db.Column(db.String(50))
    
    # 추가 정보
    operating_hours = db.Column(db.Text)  # 전체 운영시간 설명
    

    # 예약 기본 설정
    reservation_enabled = db.Column(db.Boolean, default=False)  # 예약 기능 활성화 여부
    total_seats = db.Column(db.Integer, default=0)  # 총 좌석 수
    
    # 예약 시간 설정
    reservation_start_time = db.Column(db.String(10))  # 예약 시작 시간 (예: "09:00")
    reservation_end_time = db.Column(db.String(10))   # 예약 종료 시간 (예: "22:00")
    
    # 예약 정책
    hourly_rate = db.Column(db.Integer, default=0)     # 시간당 요금 (원)
    max_advance_days = db.Column(db.Integer, default=7)  # 최대 몇일 전까지 예약 가능
    min_advance_hours = db.Column(db.Integer, default=1)  # 최소 몇시간 전까지 예약 가능


    # 타임스탬프
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f'<Cafe {self.name}>'
    


    def to_dict(self):
        """JSON 응답을 위한 딕셔너리 변환"""
        return {
            'id': self.id,
            'name': self.name,
            'address': self.address,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'message': self.message,
            'hours_weekday': self.hours_weekday,
            'hours_weekend': self.hours_weekend,
            'price': self.price,
            'video_url': self.video_url,
            'last_order': self.last_order,
            'operating_hours': {
                'monday': self.monday,
                'tuesday': self.tuesday,
                'wednesday': self.wednesday,
                'thursday': self.thursday,
                'friday': self.friday,
                'saturday': self.saturday,
                'sunday': self.sunday,
                'description': self.operating_hours
            },
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
