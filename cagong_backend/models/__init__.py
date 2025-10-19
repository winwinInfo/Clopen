from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate


db = SQLAlchemy()
migrate = Migrate()

def init_db(app):
    """데이터베이스 초기화"""
    db.init_app(app)
    migrate.init_app(app, db)

    # 모델 임포트 (순환 참조 방지를 위해 여기서)
    from .user import User
    from .cafe import Cafe
    from .reservation import Reservation
    from .cafe_time_slot import CafeTimeSlot

    return db

# 모델들을 외부에서 쉽게 임포트할 수 있도록
from .user import User
from .cafe import Cafe
from .reservation import Reservation
from .cafe_time_slot import CafeTimeSlot

