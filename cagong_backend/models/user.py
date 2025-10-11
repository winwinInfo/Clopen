from . import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

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


    # def set_password(self, password):
    #     """비밀번호 해시화"""
    #     self.password_hash = generate_password_hash(password)

    # def check_password(self, password):
    #     """비밀번호 검증"""
    #     if not self.password_hash:
    #         return False
    #     return check_password_hash(self.password_hash, password)

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
