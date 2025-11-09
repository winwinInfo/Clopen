# 테스트용임 그냥 나중에 테스트 또 하지 않을까 싶어서 놔두고 삭제 예정
from flask import Flask, jsonify, request  # <--- 1. request 임포트
import time

app = Flask(__name__)


@app.route('/v1/payments/confirm', methods=['POST'])
def mock_confirm():
    # ★★★ 여기가 핵심 ★★★

    # 2. Flask 서버가 보낸 요청(JSON)을 읽습니다.
    data = request.get_json()
    # 3. 요청에 포함된 orderId를 꺼냅니다.
    order_id_from_request = data.get("orderId", "unknown_order")

    # 4. API가 1.5초간 느리게 응답한다고 가정
    time.sleep(1.5)

    # 5. 고유한 paymentKey를 생성해서 반환합니다.
    return jsonify({
        # "paymentKey": "mock_pk_test", # <--- 기존 코드
        "paymentKey": f"mock_pk_for_{order_id_from_request}",  # <--- ★수정된 코드★
        "orderId": order_id_from_request,
        "method": "카드",
        "status": "DONE"
    })


if __name__ == '__main__':
    app.run(port=5001)