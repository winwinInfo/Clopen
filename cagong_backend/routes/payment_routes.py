# routes/payment_routes.py
from flask import Blueprint, request, jsonify, redirect, current_app

from exceptions.custom_exceptions import InvalidInputException, DuplicatePaymentException, DatabaseUpdateException, \
    OrderNotFoundException, PaymentMismatchException, PaymentApiCallException
from services import payment_service
from flask_jwt_extended import jwt_required, get_jwt_identity
from common.api_response import ApiResponse, ErrorCode


payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/create-order', methods=['POST'])
@jwt_required()
def create_order_route():
    """새로운 결제 주문 생성
    ---
    tags:
      - Payments
    security:
      - bearerAuth: []  # JWT 토큰 인증 필요
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          properties:
            item_name:
              type: string
              description: "상품 이름"
              example: "A카페 15:00 - 17:00"
            amount:
              type: integer
              description: "결제할 금액"
              example: 10000
    responses:
      201:
        description: "주문 생성 성공"
        schema:
          type: object
          properties:
            status:
              type: string
              description: "응답 상태 (ApiStatus enum)"
              example: "SUCCESS"
            message:
              type: string
              example: "새로운 주문이 성공적으로 생성되었습니다."
            data:
              type: object
              properties:
                order_id:
                  type: string
                  description: "새로 생성된 주문 ID"
                  example: "a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8"
                item_name:
                  type: string
                  description: "상품 이름"
                  example: "A카페 15:00 - 17:00"
                amount:
                  type: integer
                  description: "결제할 금액"
                  example: 10000
      400:
        description: "잘못된 요청 (예: 필수 필드 누락)"
        schema:
          type: object
          properties:
            status:
              type: string
              description: "응답 상태 (ApiStatus enum)"
              example: "FAIL"
            message:
              type: string
              example: "상품 이름과 가격 정보가 필요합니다."
            data:
              type: 'null'
              description: "실패 시 data는 항상 null 입니다."
              example: null
            errorCode:
              type: string
              description: "에러 코드 (ErrorCode enum)"
              example: "BAD_REQUEST"
      401:
        description: "인증되지 않은 사용자"
        schema:
          type: object
          properties:
            status:
              type: string
              example: "FAIL"
            message:
              type: string
              example: "인증 토큰이 유효하지 않습니다."
            data:
              type: 'null'
              example: null
            errorCode:
              type: string
              example: "AUTHENTICATION_ERROR"
      500:
        description: "서버 내부 오류"
        schema:
          type: object
          properties:
            status:
              type: string
              example: "FAIL"
            message:
              type: string
              example: "서버 내부 오류가 발생했습니다."
            data:
              type: 'null'
              example: null
            errorCode:
              type: string
              example: "INTERNAL_ERROR"
    """
    user_id = get_jwt_identity()
    # user_id = 1 (태스트용으로 썼던거 ) 삭제 예정

    data = request.get_json()
    if not data:
        return ApiResponse.fail(
            error_code=ErrorCode.BAD_REQUEST,
            message="요청 본문(JSON)이 비어있습니다.",
            http_status=400
        )

    item_name = data.get('item_name')
    amount_to_pay = data.get('amount')
    if not item_name or not amount_to_pay:
        return ApiResponse.fail(
            error_code=ErrorCode.BAD_REQUEST,
            message="상품 이름과 가격 정보가 필요합니다.",
            http_status=400
        )

    order_info = payment_service.create_new_order(user_id, item_name, amount_to_pay)

    return ApiResponse.success(
        data=order_info,
        message="새로운 주문이 성공적으로 생성되었습니다.",
        http_status=201
    )

# -----------------------------------------------------
# 2. 결제 성공 처리 (승인) API (토스 -> 백엔드)
# -----------------------------------------------------
@payments_bp.route('/success', methods=['GET'])
def payment_success_route():
    """결제 성공 처리

    성공하면 성공 URL로 실패하면 실패 URL로 리다이렉션
    ---
    tags:
      - Payments
    parameters:
      - name: paymentKey
        in: query
        type: string
        required: true
        description: "토스페이먼츠에서 발급한 결제 키"
      - name: orderId
        in: query
        type: string
        required: true
        description: "주문 ID"
      - name: amount
        in: query
        type: integer
        required: true
        description: "결제된 금액"
    responses:
      302:
        description: "결제 처리 결과에 따라 프론트엔드 페이지로 리디렉션
        (예: /payment/success?orderId=... 또는 /payment/fail?message=...)"
    """
    order_id = request.args.get('orderId')  # orderId는 성공/실패 시 모두 필요하므로 미리 가져옴

    try:
        payment_key = request.args.get('paymentKey')
        amount = request.args.get('amount')

        if not all([payment_key, order_id, amount]):
            # [변경] 기본 Exception 대신 커스텀 예외 사용
            raise InvalidInputException("필수 결제 정보가 누락되었습니다.")

        # 서비스 레이어 호출 (여기서 여러 예외가 발생할 수 있음)
        payment_service.confirm_payment(payment_key, order_id, amount)

        # --- 1. 최종 성공 ---
        current_app.logger.info(f"결제 승인 성공 (Order ID: {order_id})")
        success_page_url = f"{current_app.config['FRONTEND_URL']}/payment/success?orderId={order_id}"
        return redirect(success_page_url)

    # --- 2. 성공으로 간주 (멱등성) ---
    except DuplicatePaymentException as e:
        current_app.logger.info(f"중복 결제 요청 처리 (멱등성/성공 간주): {e}")
        success_page_url = f"{current_app.config['FRONTEND_URL']}/payment/success?orderId={order_id}"
        return redirect(success_page_url)

    # --- 3. 치명적 실패 (결제O, DB저장X) ---
    except DatabaseUpdateException as e:
        # 서비스단에서 이미 CRITICAL 로그를 남겼으므로 여기서는 ERROR
        current_app.logger.error(f"결제 승인 중 [심각] DB 저장 실패: {e}")
        # 예외에 포함된 "관리자에게 문의하세요" 메시지를 그대로 전달
        safe_error_message = str(e)
        fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={safe_error_message}&orderId={order_id}"
        return redirect(fail_page_url)

    # --- 4. 그 외 예상된 실패 (입력값, 금액 불일치, API 실패 등) ---
    except (InvalidInputException, OrderNotFoundException,
            PaymentMismatchException, PaymentApiCallException) as e:
        current_app.logger.warn(f"결제 승인 처리 중 예상된 실패: {e}")
        # 우리가 정의한 예외 메시지(str(e))는 사용자에게 보여줘도 안전함
        safe_error_message = str(e)
        fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={safe_error_message}&orderId={order_id}"
        return redirect(fail_page_url)

    # --- 5. 알 수 없는 모든 실패 (Fallback) ---
    except Exception as e:
        current_app.logger.error(f"결제 승인 처리 중 알 수 없는 에러: {e}")
        safe_error_message = "결제 처리 중 알 수 없는 오류가 발생했습니다. 관리자에게 문의하세요."
        fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={safe_error_message}&orderId={order_id}"
        return redirect(fail_page_url)


# -----------------------------------------------------
# 3. 결제 실패 처리 API (토스 -> 백엔드)
# -----------------------------------------------------
@payments_bp.route('/fail', methods=['GET'])
def payment_fail_route():
    """결제 실패 처리

    결제 실패하면 fail 페이지로 리다이렉션
    ---
    tags:
      - Payments
    parameters:
      - name: code
        in: query
        type: string
        required: true
        description: "결제 실패 에러 코드"
      - name: message
        in: query
        type: string
        required: true
        description: "결제 실패 메시지"
      - name: orderId
        in: query
        type: string
        required: true
        description: "주문 ID"
    responses:
      302:
        description: "결제 실패 처리 후 프론트엔드 실패 페이지로 리디렉션
        (예: /payment/fail?message=...&orderId=...)"
    """
    error_code = request.args.get('code')
    error_message = request.args.get('message')
    order_id = request.args.get('orderId')

    try:
        # [중요] 결제 실패 사실을 DB에 '기록'하려 시도합니다.
        # 이 호출이 실패하더라도, 사용자 리디렉션은 계속되어야 합니다.
        payment_service.handle_payment_failure(order_id, error_code, error_message)

    except Exception as e:
        # DB 저장에 실패하더라도, 사용자를 실패 페이지로 보내는 것이 더 중요합니다.
        # 이 에러는 서버 내부에서만 알면 되고, 사용자에게 알릴 필요가 없습니다.
        current_app.logger.error(f"결제 실패 '기록' 중 오류 발생 (사용자 리디렉션은 계속): {e}")

    # [중요] 어떠한 경우에도 사용자를 프론트엔드 실패 페이지로 리디렉션합니다.
    fail_page_url = f"{current_app.config['FRONTEND_URL']}/payment/fail?message={error_message}&orderId={order_id}"
    return redirect(fail_page_url)