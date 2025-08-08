from . import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import uuid

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    google_id = db.Column(db.String(255), unique=True, nullable=False)  # Google의 'sub'
    email = db.Column(db.String(120), unique=True, nullable=False)
    name = db.Column(db.String(50), nullable=False)
    photo_url = db.Column(db.String(500))  # 프로필 이미지 URL
    role = db.Column(db.String(20), default='user')  # user/owner/admin
    provider = db.Column(db.String(20), default='email')  # email, google
    provider_id = db.Column(db.String(255))  # OAuth provider ID
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


    def set_password(self, password):
        """비밀번호 해시화"""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """비밀번호 검증"""
        if not self.password_hash:
            return False
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        """JSON 응답용 딕셔너리 변환"""
        return {
            'id': self.id,
            'email': self.email,
            'name': self.name,
            'nickname': self.nickname,
            'gender': self.gender,
            'birth_date': self.birth_date.isoformat() if self.birth_date else None,
            'university': self.university,
            'photo_url': self.photo_url,
            'role': self.role,
            'provider': self.provider,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

    def __repr__(self):
        return f"<User {self.email}>"

    def to_dict(self):
        return {
            "id": self.id,
            "google_id": self.google_id,
            "email": self.email,
            "name": self.name,
            "photo_url": self.photo_url,
            "role": self.role,
            "created_at": self.created_at.isoformat()
        }
