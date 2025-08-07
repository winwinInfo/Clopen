from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    google_id = db.Column(db.String(255), unique=True, nullable=False)  # Google의 'sub'
    email = db.Column(db.String(120), unique=True, nullable=False)
    name = db.Column(db.String(50), nullable=False)
    photo_url = db.Column(db.String(500))  # 프로필 이미지 URL
    role = db.Column(db.String(20), default='user')  # user/owner/admin
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

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
