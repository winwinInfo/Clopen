import requests
import base64
from flask import current_app, abort
from models import db
from models.order import Order


# -----------------------------------------------------
# 1. 주문 생성 서비스 로직
# -----------------------------------------------------
def create_new_order(user_id, item_name, amount):
    """
    새로운 주문을 생성하고 'PENDING' 상태로 DB에 저장합니다.
    """
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

    # 컨트롤러(routes)에 결제창 띄우는 데 필요한 정보를 반환합니다.
    return {
        'orderId': new_order.order_id,
        'orderName': new_order.order_name,
        'amount': new_order.amount,
        'customerName': new_order.user.name  # User 모델과 연결되어 있으므로 바로 접근 가능
    }


# -----------------------------------------------------
# 2. 결제 최종 승인 서비스 로직 (가장 중요)
# -----------------------------------------------------
def confirm_payment(payment_key, order_id, amount, payment_type):
    """
    DB 검증 후, 토스페이먼츠에 최종 결제 승인을 요청합니다.
    """
    # 1. 내부 DB 검증 (우리 장부 먼저 확인)
    order = Order.query.filter_by(order_id=order_id).first()
    if not order:
        raise Exception("존재하지 않는 주문입니다.")

    # 이미 처리된 주문인지 확인
    if order.status == 'PAID':
        print(f"이미 처리된 주문입니다: {order_id}")
        return {"message": "이미 처리된 주문입니다."}

    # 금액 일치 확인 (가격 위변조 방지)
    if order.amount != int(amount):
        raise Exception("주문 금액이 일치하지 않습니다.")

    # 2. 토스페이먼츠 API 호출 (카드사에 직접 확인)
    url = "https://api.tosspayments.com/v1/payments/confirm"

    # 시크릿 키를 base64로 인코딩 (토스 API 인증 방식)
    secret_key = current_app.config['TOSS_SECRET_KEY']
    encoded_key = base64.b64encode(f"{secret_key}:".encode('utf-8')).decode('utf-8')

    headers = {
        "Authorization": f"Basic {encoded_key}",
        "Content-Type": "application/json"
    }

    params = {
        "paymentKey": payment_key,
        "orderId": order_id,
        "amount": int(amount)
    }

    try:
        # 1. 토스에 결제 승인 요청 (외부 통신)
        response = requests.post(url, json=params, headers=headers)
        response.raise_for_status()  # HTTP 에러 발생 시 아래 except로 바로 이동
        response_data = response.json()

        # 2. DB 저장 시도 (내부 처리)
        try:
            # 2-1. DB 상태 업데이트
            order.status = 'PAID'
            order.payment_key = response_data.get('paymentKey')
            order.payment_type = payment_type
            db.session.commit()

            current_app.logger.info(f"결제 최종 승인 및 DB 저장 성공: {order_id}")
            return response_data

        except Exception as db_error:
            # 2-2. DB 저장 실패 시 -> 결제 자동 취소 로직 실행
            current_app.logger.error(f"DB 저장 실패! 결제를 자동 취소합니다. (오류: {db_error})")
            # 방금 성공한 결제를 즉시 취소(환불) 처리
            cancel_payment(payment_key, "서버 DB 저장 오류로 인한 자동 취소")
            # 프론트엔드에 에러 전달
            raise Exception("결제는 성공했으나 서버 처리 중 오류가 발생하여 자동으로 취소되었습니다.")

    except requests.exceptions.HTTPError as e:
        # 1-1. 토스 API 통신 자체가 실패한 경우
        current_app.logger.error(f"결제 승인 실패 (토스 API 에러): {e.response.json()}")
        raise Exception(e.response.json().get("message", "결제 승인에 실패했습니다."))


# -----------------------------------------------------
# 3. 결제 실패 처리 서비스 로직
# -----------------------------------------------------
def handle_payment_failure(order_id, error_code, error_message):
    """
    결제 실패 시 원인을 기록(logging)합니다.
    """
    # 간단한 예시로 print를 사용하지만, 실제로는 logging 라이브러리를 사용하는 것이 좋습니다.
    print(f"[결제 실패] 주문번호: {order_id}, 오류코드: {error_code}, 메시지: {error_message}")

    order = Order.query.filter_by(order_id=order_id).first()
    if order and order.status != 'PAID':
        order.status = 'FAILED'
        db.session.commit()
        current_app.logger.info(f"주문 {order_id}의 상태를 'FAILED'로 변경했습니다.")

    return {"status": "failure_handled"}


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