from datetime import datetime

from . import db

class CafeRating(db.Model):
    __tablename__ = 'cafe_ratings'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.id'), nullable=False)

    # 카공점수
    rate = db.Column(db.Integer, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # 중복 방지 (유저-카페 한 쌍은 1개만)
    __table_args__ = (
        db.UniqueConstraint('user_id', 'cafe_id', name='unique_user_cafe_rating'),
    )

    def __repr__(self):
        return f"<CafeRating user_id={self.user_id} cafe_id={self.cafe_id} rate={self.rate}>"

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "cafe_id": self.cafe_id,
            "rate": self.rate,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat()
        }
