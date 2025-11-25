from datetime import datetime

from . import db

class CafeLike(db.Model):
    __tablename__ = 'cafe_likes'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.id'), nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # 중복 방지 (유저-카페 한 쌍은 1개만)
    __table_args__ = (
        db.UniqueConstraint('user_id', 'cafe_id', name='unique_user_cafe_like'),
    )
