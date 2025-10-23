# routes/payment_routes.py

from flask import Blueprint, request, jsonify, redirect, current_app
from services import payment_service
from flask_jwt_extended import jwt_required, get_jwt_identity

payments_bp = Blueprint('payments', __name__, url_prefix='/api/payments')


# ... (create_order_route 함수는 그대로) ...
@payments_bp.route('/create-order', methods=['POST'])
@jwt_required()
def create_order_route():
    # ... (기존 코드와 동일)
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        item_name = data.get('item_name')
        amount_to_pay = data.get('amount')
        if not item_name or not amount_to_pay:
            return jsonify({'error': '상품 이름과 가격 정보가 필요합니다.'}), 400
        order_info = payment_service.create_new_order(user_id, item_name, amount_to_pay)
        return jsonify(order_info), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# -----------------------------------------------------
# 2. 결제 성공 처리 (승인) API (토스 -> 백엔드)
# -----------------------------------------------------
@payments_bp.route('/success', methods=['GET'])
def payment_success_route():
    """
    토스페이먼츠에서 결제가 성공적으로 끝나면, 사용자는 이 경로로 리디렉션됩니다.
    여기서 최종 결제 승인을 요청합니다.
    """
    try:
        payment_key = request.args.get('paymentKey')
        order_id = request.args.get('orderId')
        amount = request.args.get('amount')

        if not all([payment_key, order_id, amount]):
            raise Exception("필수 결제 정보가 누락되었습니다.")

        payment_service.confirm_payment(payment_key, order_id, amount)

        success_page_url = f"{current_app.config['FRONTEND_URL']}/payment/success?orderId={order_id}"
        return redirect(success_page_url)

    except Exception as e:
        # 1. 서버 내부에는 정확한 에러 원인을 로그로 남깁니다.
        current_app.logger.error(f"결제 승인 처리 중 에러 발생: {e}")

        # 2. 사용자(프론트엔드)에게는 안전한 일반 메시지를 전달합니다.
        safe_error_message = "결제 처리 중 오류가 발생했습니다. 관리자에게 문의하세요."
        fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={safe_error_message}"
        return redirect(fail_page_url)


# -----------------------------------------------------
# 3. 결제 실패 처리 API (토스 -> 백엔드)
# -----------------------------------------------------
@payments_bp.route('/fail', methods=['GET'])
def payment_fail_route():
    """
    사용자가 결제를 취소하거나 실패하면 이 경로로 리디렉션됩니다.
    """
    error_code = request.args.get('code')
    error_message = request.args.get('message')
    order_id = request.args.get('orderId')

    payment_service.handle_payment_failure(order_id, error_code, error_message)

    # 여기도 str(e) 대신 전달받은 error_message를 사용하는 것이 좋습니다.
    fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={error_message}"
    return redirect(fail_page_url)