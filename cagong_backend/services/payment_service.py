import requests
import base64
from flask import current_app, abort
from sqlalchemy.exc import SQLAlchemyError

from exceptions.custom_exceptions import (InvalidInputException, UserNotFoundException, PaymentApiCallException,
                                          OrderNotFoundException, DuplicatePaymentException, PaymentMismatchException,
                                          DatabaseUpdateException)
from models import db, User
from models.order import Order


# -----------------------------------------------------
# 1. 주문 생성 서비스 로직
# -----------------------------------------------------
def create_new_order(user_id, item_name, amount):
    """
    새로운 주문을 생성하고 'PENDING' 상태로 DB에 저장합니다.
    """

    user = User.query.get(user_id)
    if not user:
        raise UserNotFoundException(f"ID가 {user_id}인 사용자를 찾을 수 없습니다.")

    if not isinstance(amount, int) or amount <= 0:
        raise InvalidInputException(f"주문 금액은 0보다 큰 정수여야 합니다. (입력값: {amount})")

    # Order 모델을 이용해 새로운 주문 객체를 만듭니다.
    new_order = Order(
        user_id=user_id,
        order_name=item_name,  # 모델의 order_name 필드에 item_name을 저장
        amount=amount,
        status='PENDING'  # 초기 상태는 '결제 대기'
    )

    # DB에 추가하고 변경사항을 확정(commit)합니다.
    db.session.add(new_order)
    db.session.commit()


    return {
        'orderId': new_order.order_id,
        'orderName': new_order.order_name,
        'amount': new_order.amount,
        'customerName': user.name
    }


def _call_toss_api(method, url, json_data=None):
    """Toss API 호출"""
    try:
        secret_key = current_app.config['TOSS_SECRET_KEY']
        encoded_key = base64.b64encode(f"{secret_key}:".encode('utf-8')).decode('utf-8')
        headers = {
            "Authorization": f"Basic {encoded_key}",
            "Content-Type": "application/json"
        }

        # POST 요청만 처리 (confirm, cancel 등)
        response = requests.post(url, json=json_data, headers=headers, timeout=10)

        # HTTP 4xx, 5xx 에러 시 예외 발생
        response.raise_for_status()
        return response.json()

    except requests.exceptions.HTTPError as e:
        # API가 반환한 구체적인 에러 메시지를 포함하여 예외 발생
        error_details = e.response.json()
        raise PaymentApiCallException(f"Toss API Error: {error_details.get('message', e.response.text)}")

    except requests.exceptions.RequestException as e:
        # 네트워크 타임아웃 등
        current_app.logger.error(f"Toss API 통신 실패: {e}")
        raise PaymentApiCallException(f"API 통신 중 오류가 발생했습니다: {e}")


# -----------------------------------------------------
# 2. 결제 최종 승인 서비스 로직 (가장 중요)
# -----------------------------------------------------
def confirm_payment(payment_key, order_id, amount):
    # === 1. [트랜잭션 A]: 락(Lock) 걸고, 검증하고, 'PROCESSING'으로 선점 ===
    # 이 트랜잭션은 0.01초 안에 끝나야 합니다.
    try:
        # with_for_update(): 락(lock)을 걸어 동시 접근을 막습니다.
        order = Order.query.filter_by(order_id=order_id).with_for_update().first()

        if not order:
            raise OrderNotFoundException(f"주문 ID {order_id}를 찾을 수 없습니다.")

        # 멱등성(Idempotency) 처리
        if order.status == 'PAID':
            current_app.logger.info(f"이미 처리된 주문입니다: {order_id}")
            raise DuplicatePaymentException("이미 처리된 주문입니다.")

        # [신규] 이미 PROCESSING 상태인 경우 (다른 요청이 처리 중)
        if order.status == 'PROCESSING':
            current_app.logger.warn(f"이미 처리 중인 주문입니다 (동시 접근): {order_id}")
            raise DuplicatePaymentException("이미 처리 중인 주문입니다.")

        # 서버 측 금액 검증 (위변조 방지)
        if order.amount != int(amount):
            raise PaymentMismatchException("주문 금액이 일치하지 않습니다.")


        # 상태를 'PAID'가 아닌 'PROCESSING'으로 변경합니다.
        order.status = 'PROCESSING'
        # 즉시 커밋하여 락을 해제합니다.
        db.session.commit()
        # --- [트랜잭션 A 종료] ---

    except SQLAlchemyError as e:
        db.session.rollback()  # DB 세션 원상 복구
        current_app.logger.error(f"결제 승인 중 DB 오류: {e}")
        raise DatabaseUpdateException("주문 처리 중 DB 오류가 발생했습니다.")
    except (OrderNotFoundException, DuplicatePaymentException, PaymentMismatchException) as e:
        # 검증 실패는 롤백이 필요 없거나(조회) 이미 됐으므로(SQLAlchemyError) 바로 re-raise
        db.session.rollback()  # 혹시 모를 세션 롤백
        raise e

    # === 2. [외부 API 호출]: 락이 없는(No-Lock) 상태에서 실행 ===
    # 이 작업이 1.5초(Mock)가 걸려도 DB 커넥션 풀과 무관합니다.

    url = "https://api.tosspayments.com/v1/payments/confirm"
    # url = "http://127.0.0.1:5001/v1/payments/confirm"  # Mock API
    params = {
        "paymentKey": payment_key,
        "orderId": order_id,
        "amount": int(amount)
    }

    try:
        response_data = _call_toss_api('POST', url, json_data=params)

    except PaymentApiCallException as api_error:
        # API 호출 자체가 실패! (e.g., 토스가 4xx/5xx 반환)
        current_app.logger.error(f"Toss 결제 승인 API 실패 (order_id: {order_id}): {api_error}")

        # --- ★★★ 핵심 변경점 2 ★★★ ---
        # [트랜잭션 C]: API 호출 실패 시, 'FAILED'로 상태 확정
        try:
            # 'order' 객체는 T-A 세션이므로, 새 세션에서 객체를 다시 조회
            order_to_fail = Order.query.get(order.id)
            if order_to_fail and order_to_fail.status == 'PROCESSING':
                order_to_fail.status = 'FAILED'
                db.session.commit()
        except SQLAlchemyError as db_fail_error:
            db.session.rollback()
            current_app.logger.critical(
                f"!!!!!!!!!! [심각] API 실패 후 'FAILED' 상태 변경조차 실패 !!!!!!!!!!\n"
                f"주문 ID: {order_id}, 오류: {db_fail_error}"
            )

        # API 오류를 라우트(컨트롤러)로 다시 전달
        raise api_error

    # === 3. [트랜잭션 B]: API 성공 시, 'PAID'로 최종 상태 확정 ===
    try:
        # T-A 세션과 분리하기 위해, order 객체를 id로 다시 조회하는 것이 가장 안전
        order_to_pay = Order.query.get(order.id)

        if not order_to_pay or order_to_pay.status != 'PROCESSING':
            current_app.logger.error(f"결제 승인 [T-B: 최종 확정] 실패. 주문이 PROCESSING 상태가 아님: {order_id}")
            raise DatabaseUpdateException("주문 상태가 올바르지 않아 처리에 실패했습니다.")

        order_to_pay.status = 'PAID'
        order_to_pay.payment_key = response_data.get('paymentKey')
        order_to_pay.payment_type = response_data.get('method')

        db.session.commit()  # <--- [트랜잭션 B 종료]

        current_app.logger.info(f"결제 최종 승인 및 DB 저장 성공: {order_id}")
        return response_data  # <--- 유일한 성공 종료 지점

    except SQLAlchemyError as db_error:
        # 이 시나리오는 "결제는 성공했으나 DB 저장을 실패"한 최악의 경우입니다.
        db.session.rollback()

        # (기존의 훌륭한 CRITICAL 로그)
        current_app.logger.critical(
            "!!!!!!!!!! [심각] 결제 성공 후 DB 저장 실패 !!!!!!!!!!\n"
            f"주문 ID: {order_id}, Payment Key: {payment_key}\n"
            f"오류: {db_error}\n"
            "!!!!!!!!!! 즉시 [수동 환불] 및 원인 파악 필요 !!!!!!!!!!"
        )
        raise DatabaseUpdateException(
            "결제는 성공했으나, 서버 내부 오류로 주문 처리에 실패했습니다. 즉시 관리자에게 문의하세요."
        )
# -----------------------------------------------------
# 3. 결제 실패 처리 서비스 로직
# -----------------------------------------------------
def handle_payment_failure(order_id, error_code, error_message):
    """
     결제 실패 시 원인을 기록하고 DB 상태를 FAILED로 변경합니다.
    """
    current_app.logger.warn(f"[결제 실패] 주문번호: {order_id}, 오류코드: {error_code}, 메시지: {error_message}")

    try:
        order = Order.query.filter_by(order_id=order_id).first()

        if order and order.status != 'PAID':  # 이미 성공한 결제를 덮어쓰지 않도록
            order.status = 'FAILED'
            # (필요시) order.fail_reason = f"{error_code}: {error_message}"
            db.session.commit()
            current_app.logger.info(f"주문 {order_id}의 상태를 'FAILED'로 변경했습니다.")

        return {"status": "failure_handled"}

    except SQLAlchemyError as e:
        # [추가] DB 커밋 실패 시 롤백
        db.session.rollback()
        current_app.logger.error(f"결제 실패 상태 DB 업데이트 중 오류: {e}")

        # [중요] 이 함수는 실패해도 예외를 raise하지 않습니다.
        return {"status": "failure_logging_failed"}


def cancel_payment(payment_key, cancel_reason="서버 내부 오류로 인한 자동 취소"):
    """
    paymentKey를 이용해 토스페이먼츠에 결제 취소(환불)를 요청합니다.
    """
    url = f"https://api.tosspayments.com/v1/payments/{payment_key}/cancel"
    secret_key = current_app.config['TOSS_SECRET_KEY']
    encoded_key = base64.b64encode(f"{secret_key}:".encode('utf-8')).decode('utf-8')
    headers = {
        "Authorization": f"Basic {encoded_key}",
        "Content-Type": "application/json"
    }
    params = {"cancelReason": cancel_reason}

    try:
        response = requests.post(url, json=params, headers=headers)
        response.raise_for_status()
        current_app.logger.info(f"결제 자동 취소 성공: {payment_key}")
        return response.json()
    except requests.exceptions.HTTPError as e:
        current_app.logger.error(f"결제 자동 취소 실패: {e.response.json()}")
        # 취소마저 실패하면 심각한 상태이므로, 별도 모니터링/알림 필요
        raise Exception("결제 자동 취소에 실패했습니다. 즉시 확인이 필요합니다.")


def _mark_order_as_failed(order, error_code, error_message):
    """[신규] 결제 실패 시 DB 상태를 FAILED로 기록하는 내부 헬퍼"""
    try:
        if order and order.status != 'PAID': # 이미 성공한 건 덮어쓰기 방지
            order.status = 'FAILED'
            # (필요시) order.fail_reason = f"{error_code}: {error_message}"
            db.session.commit()
    except SQLAlchemyError as e:
        # 실패를 기록하는 것마저 실패하면, 롤백하고 로그만 남깁니다.
        db.session.rollback()
        current_app.logger.error(f"결제 실패 상태 DB 업데이트 중 오류: {e}")