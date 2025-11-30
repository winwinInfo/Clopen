import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PaymentService {
  /// 주문 생성 (결제 전 서버에 주문 등록)
  ///
  /// [jwtToken]: 인증 토큰
  /// [itemName]: 상품명 (예: "A카페 15:00 - 17:00")
  /// [amount]: 결제 금액
  /// Returns: 주문 정보 (orderId, orderName, amount, customerName)
  static Future<Map<String, dynamic>> createOrder({
    required String jwtToken,
    required String itemName,
    required int amount,
  }) async {
    print("토큰 디버깅:");
    print(jwtToken);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/payments/create-order');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'item_name': itemName,
          'amount': amount,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['status'] == 'SUCCESS') {
        return responseData['data'];
      } else {
        throw Exception(responseData['message'] ?? '주문 생성에 실패했습니다');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 토스페이먼츠 결제 URL 생성
  ///
  /// [orderId]: 주문 ID
  /// [orderName]: 주문명
  /// [amount]: 결제 금액
  /// [customerName]: 고객명
  /// Returns: 토스페이먼츠 결제 URL
  static String getTossPaymentUrl({
    required String orderId,
    required String orderName,
    required int amount,
    required String customerName,
  }) {
    // 토스페이먼츠 클라이언트 키 (테스트용)
    const clientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';

    // 성공/실패 리다이렉트 URL (백엔드 API)
    final successUrl = Uri.encodeComponent('${ApiConfig.baseUrl}/payments/success');
    final failUrl = Uri.encodeComponent('${ApiConfig.baseUrl}/payments/fail');

    // 토스페이먼츠 결제 위젯 URL
    return 'https://pay.toss.im/v2/checkout/payment?'
        'clientKey=$clientKey'
        '&orderId=$orderId'
        '&orderName=${Uri.encodeComponent(orderName)}'
        '&amount=$amount'
        '&customerName=${Uri.encodeComponent(customerName)}'
        '&successUrl=$successUrl'
        '&failUrl=$failUrl';
  }
}

/// 결제 결과
class PaymentResult {
  final bool success;
  final String? orderId;
  final String? paymentKey;
  final String? message;

  PaymentResult({
    required this.success,
    this.orderId,
    this.paymentKey,
    this.message,
  });
}
