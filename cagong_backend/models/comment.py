from . import db
from datetime import datetime

class Comment(db.Model):
    __tablename__ = 'comments'

    # 1. PK
    id = db.Column(db.Integer, primary_key=True)

    # 2. FK: 작성자 (User 테이블의 id 참조)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)

    # 3. FK: 어떤 카페에 달린 댓글인지 (Cafe 테이블의 id 참조)
    cafe_id = db.Column(db.Integer, db.ForeignKey('cafes.id', ondelete='CASCADE'), nullable=False)

    # 4. 내용 (description)
    content = db.Column(db.Text, nullable=False)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # 관계 설정 (Join을 편하게 하기 위해)
    # 이렇게 하면 comment.user 로 작성자 정보에 바로 접근 가능합니다.
    user = db.relationship('User', backref=db.backref('comments', lazy=True))
    cafe = db.relationship('Cafe', backref=db.backref('comments', lazy=True))

    def __repr__(self):
        return f'<Comment {self.id} by User {self.user_id} on Cafe {self.cafe_id}>'

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_nickname': self.user.nickname if self.user else "알 수 없음",
            'user_photo': self.user.photo_url if self.user else None,
            'cafe_id': self.cafe_id,
            'content': self.content,
            'created_at': self.created_at.isoformat()
        }