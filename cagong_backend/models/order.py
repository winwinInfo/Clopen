from . import db
import uuid
from datetime import datetime


class Order(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)

    # 외부에 노출될 고유 주문 ID (UUID 사용 권장)
    order_id = db.Column(db.String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))

    #  User 모델과의 연결 (Foreign Key)
    # 'users.id'는 'users' 테이블의 'id' 컬럼을 참조합니다.
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # 결제 상태: PENDING(대기), PAID(완료), FAILED(실패), CANCELED(취소)
    status = db.Column(db.String(20), nullable=False, default='PENDING')

    # 결제 금액
    amount = db.Column(db.Integer, nullable=False)

    # 주문 이름 (예: "티셔츠 외 2건") - 사용자에게 보여줄 때 사용
    order_name = db.Column(db.String(100), nullable=False)

    # 토스페이먼츠 결제 승인 후 받는 고유 키 (환불/조회에 사용)
    payment_key = db.Column(db.String(200), unique=True, nullable=True)  # 결제 완료 전에는 NULL

    payment_type = db.Column(db.String(20), nullable=True) # 결제 타입 저장용

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    #  SQLAlchemy Relationship 설정
    # 이를 통해 order.user 형태로 User 객체에 바로 접근 가능
    # user.orders 형태로 해당 유저의 모든 주문 목록에 접근 가능 (lazy='dynamic' 추천)
    user = db.relationship('User', backref=db.backref('orders', lazy='dynamic'))

    def __repr__(self):
        return f"<Order {self.order_id}>"

    def to_dict(self):
        return {
            "order_id": self.order_id,
            "user_id": self.user_id,
            "status": self.status,
            "amount": self.amount,
            "order_name": self.order_name,
            "created_at": self.created_at.isoformat()
        }