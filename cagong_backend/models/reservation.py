from . import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid


# Reservation 모델 
class Reservation(db.Model):
    __tablename__ = 'reservations'
    
    id = db.Column(db.Integer, primary_key=True)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

    # 예약 시간 정보 (분 단위 정확도)
    start_datetime = db.Column(db.DateTime, nullable=False)  # 2024-01-15 13:30:00
    end_datetime = db.Column(db.DateTime, nullable=False)    # 2024-01-15 15:30:00
    
    # 예약 좌석 수
    seat_count = db.Column(db.Integer, nullable=False)  # 예약한 좌석 수

    # 결제 정보
    total_amount = db.Column(db.Integer, default=0)

    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)