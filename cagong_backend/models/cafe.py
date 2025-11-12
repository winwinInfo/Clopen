from . import db
from datetime import datetime


# 카페 모델인데 예약 관련 필드도 포함

class Cafe(db.Model):
    __tablename__ = 'cafes'
    

    # 기본 정보
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.Text, nullable=False)


    # 위치 정보(좌표) - GPS 정밀도를 위해 Numeric 사용
    latitude = db.Column(db.Numeric(precision=10, scale=7), nullable=False)
    longitude = db.Column(db.Numeric(precision=10, scale=7), nullable=False)
    

    # 운영 정보
    message         = db.Column(db.Text)            # 카페 소개 한 줄
    hours_weekday   = db.Column(db.Integer)     # 권장 이용 시간
    hours_weekend   = db.Column(db.Integer)     # 권장 이용 시간
    price           = db.Column(db.String(50))        # 아아 가격
    video_url       = db.Column(db.String(255))   # 카페 내부 영상
    last_order      = db.Column(db.String(50))   # 라스트 오더 시간
    

    # 요일별 운영시간(날마다 다른 경우가 있음...) - HH:MM 형식의 문자열
    monday_begin        = db.Column(db.String(5))      # 예: "09:00"
    monday_end          = db.Column(db.String(5))      # 예: "22:00"
    tuesday_begin       = db.Column(db.String(5))
    tuesday_end         = db.Column(db.String(5))
    wednesday_begin     = db.Column(db.String(5))
    wednesday_end       = db.Column(db.String(5))
    thursday_begin      = db.Column(db.String(5))
    thursday_end        = db.Column(db.String(5))
    friday_begin        = db.Column(db.String(5))
    friday_end          = db.Column(db.String(5))
    saturday_begin      = db.Column(db.String(5))
    saturday_end        = db.Column(db.String(5))
    sunday_begin        = db.Column(db.String(5))
    sunday_end          = db.Column(db.String(5))


    # 추가 정보
    operating_hours = db.Column(db.Text)  # 전체 운영시간 설명(ex 평일 09~20, 주말 14~22 처럼 설명)
    

    # 예약 기본 설정
    reservation_enabled = db.Column(db.Boolean, default=False)  # 예약 기능 활성화 여부
    total_seats = db.Column(db.Integer, default=0)  # 총 좌석 수
    total_consents = db.Column(db.Integer, default=0)  # 총 콘센트 수 (0이면 콘센트 없음)
    

    # 예약 시간 설정 - HH:MM 형식의 문자열
    reservation_start_time = db.Column(db.String(5))  # 예약 시작 시간 (예: "09:00")
    reservation_end_time = db.Column(db.String(5))    # 예약 종료 시간 (예: "22:00")
    

    # 예약 정책
    hourly_rate = db.Column(db.Integer, default=0)     # 30분당 요금(원)


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
                'monday': {
                    'begin': self.monday_begin,
                    'end': self.monday_end
                },
                'tuesday': {
                    'begin': self.tuesday_begin,
                    'end': self.tuesday_end
                },
                'wednesday': {
                    'begin': self.wednesday_begin,
                    'end': self.wednesday_end
                },
                'thursday': {
                    'begin': self.thursday_begin,
                    'end': self.thursday_end
                },
                'friday': {
                    'begin': self.friday_begin,
                    'end': self.friday_end
                },
                'saturday': {
                    'begin': self.saturday_begin,
                    'end': self.saturday_end
                },
                'sunday': {
                    'begin': self.sunday_begin,
                    'end': self.sunday_end
                },
                'description': self.operating_hours
            },
            'reservation': {
                'enabled': self.reservation_enabled,
                'total_seats': self.total_seats,
                'total_consents': self.total_consents,
                'start_time': self.reservation_start_time,
                'end_time': self.reservation_end_time,
                'hourly_rate': self.hourly_rate
            },
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
