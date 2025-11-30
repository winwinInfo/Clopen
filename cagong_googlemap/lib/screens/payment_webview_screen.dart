import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import '../services/payment_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;
  final String orderName;
  final int amount;
  final String customerName;

  const PaymentWebViewScreen({
    super.key,
    required this.orderId,
    required this.orderName,
    required this.amount,
    required this.customerName,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late PaymentWidget _paymentWidget;
  PaymentMethodWidgetControl? _paymentMethodWidgetControl;
  AgreementWidgetControl? _agreementWidgetControl;

  @override
  void initState() {
    super.initState();

    _paymentWidget = PaymentWidget(
      clientKey: 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm',
      customerKey: 'customer_${widget.orderId}',
    );

    _paymentWidget.renderPaymentMethods(
      selector: 'methods',
      amount: Amount(value: widget.amount, currency: Currency.KRW, country: 'KR'),
    ).then((control) {
      _paymentMethodWidgetControl = control;
    });

    _paymentWidget.renderAgreement(selector: 'agreement').then((control) {
      _agreementWidgetControl = control;
    });
  }

  Future<void> _requestPayment() async {
    try {
      final result = await _paymentWidget.requestPayment(
        paymentInfo: PaymentInfo(
          orderId: widget.orderId,
          orderName: widget.orderName,
        ),
      );

      if (!mounted) return;

      if (result.success != null) {
        // 결제 성공
        Navigator.of(context).pop(PaymentResult(
          success: true,
          orderId: result.success!.orderId,
          paymentKey: result.success!.paymentKey,
          message: '결제가 완료되었습니다',
        ));
      } else if (result.fail != null) {
        // 결제 실패
        Navigator.of(context).pop(PaymentResult(
          success: false,
          message: result.fail!.errorMessage,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(PaymentResult(
        success: false,
        message: '결제 중 오류가 발생했습니다: $e',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        title: const Text(
          '결제하기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop(PaymentResult(
              success: false,
              message: '결제가 취소되었습니다',
            ));
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // 주문 정보
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.orderName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.amount}원',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 결제 수단 위젯
                  PaymentMethodWidget(
                    paymentWidget: _paymentWidget,
                    selector: 'methods',
                  ),
                  // 약관 동의 위젯
                  AgreementWidget(
                    paymentWidget: _paymentWidget,
                    selector: 'agreement',
                  ),
                ],
              ),
            ),
            // 결제하기 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _requestPayment,
                child: Text(
                  '${widget.amount}원 결제하기',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
