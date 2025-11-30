import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cafe.dart';
import '../services/reservation_service.dart';
import '../services/payment_service.dart';
import '../utils/authProvider.dart' as loginProvider;
import 'payment_webview_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Cafe cafe;

  const ReservationDetailScreen({
    super.key,
    required this.cafe,
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  // 오늘 날짜
  late String _selectedDate;

  // 선택된 시작 시간 (30분 단위)
  String? _selectedStartTime;

  // 선택된 예약 시간 (1시간, 2시간, ...)
  int? _selectedDuration;

  // 예약 가능 여부
  bool _isAvailable = false;

  // 예약 가능 여부 확인 중
  bool _isCheckingAvailability = false;

  // 예약 관련 메시지
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();

    // 오늘 날짜를 YYYY-MM-DD 형식으로 설정
    final now = DateTime.now();
    _selectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 예약 가능 여부 확인
  Future<void> _checkAvailability() async {
    if (_selectedStartTime == null || _selectedDuration == null) {
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final result = await ReservationService.checkAvailability(
        cafeId: widget.cafe.id,
        date: _selectedDate,
        time: _selectedStartTime!,
        duration: _selectedDuration!,
      );

      setState(() {
        _isAvailable = result['is_available'] ?? false;
        _availabilityMessage = result['message'];
        _isCheckingAvailability = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _availabilityMessage = '예약 가능 여부 확인 중 오류가 발생했습니다: $e';
        _isCheckingAvailability = false;
      });
    }
  }

  /// 예약 시간 목록 생성 (1시간 ~ 6시간)
  List<int> _generateDurationOptions() {
    return List.generate(6, (index) => index + 1);
  }

  /// 결제하기 버튼 핸들러
  Future<void> _handlePayment() async {
    // AuthProvider에서 user_id 가져오기
    final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    final jwtToken = authProvider.jwtToken;

    if (userData == null || userData['id'] == null || jwtToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final userId = userData['id'] as int;
    final totalAmount = (widget.cafe.reservation.hourlyRate ?? 0) * _selectedDuration!;

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.brown),
      ),
    );

    try {
      // 1. 주문 생성
      final orderInfo = await PaymentService.createOrder(
        jwtToken: jwtToken,
        itemName: '${widget.cafe.name} $_selectedStartTime ${_selectedDuration}시간',
        amount: totalAmount,
      );

      if (!mounted) return;

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 2. 결제 WebView로 이동
      final paymentResult = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          builder: (context) => PaymentWebViewScreen(
            orderId: orderInfo['orderId'],
            orderName: orderInfo['orderName'],
            amount: orderInfo['amount'],
            customerName: orderInfo['customerName'],
          ),
        ),
      );

      if (!mounted) return;

      // 3. 결제 성공 시 예약 생성
      if (paymentResult != null && paymentResult.success) {
        // 로딩 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Colors.brown),
          ),
        );

        final result = await ReservationService.createReservation(
          cafeId: widget.cafe.id,
          userId: userId,
          date: _selectedDate,
          time: _selectedStartTime!,
          duration: _selectedDuration!,
          seatCount: 1,
          paymentKey: paymentResult.paymentKey,
        );

        if (!mounted) return;

        // 로딩 다이얼로그 닫기
        Navigator.of(context).pop();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '예약이 완료되었습니다'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.of(context).pop();
      } else {
        // 결제 실패 또는 취소
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentResult?.message ?? '결제가 취소되었습니다'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;

      // 로딩 다이얼로그 닫기 (열려있는 경우)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '예약 상세',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카페 기본 정보
            _buildCafeInfo(),
            const SizedBox(height: 24),

            // 날짜 표시
            _buildDateSection(),
            const SizedBox(height: 24),

            // 시작 시간 선택
            _buildStartTimeDropdown(),
            const SizedBox(height: 16),

            // 예약 시간 선택
            _buildDurationDropdown(),
            const SizedBox(height: 24),

            // 예약 가능 여부 메시지
            if (_selectedStartTime != null && _selectedDuration != null) ...[
              _buildAvailabilityMessage(),
              const SizedBox(height: 24),
            ],

            // 결제하기 버튼
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  /// 카페 정보 섹션
  Widget _buildCafeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.cafe.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.cafe.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                Icons.event_seat,
                '총 좌석',
                '${widget.cafe.reservation.totalSeats ?? 0}석',
              ),
              _buildInfoItem(
                Icons.attach_money,
                '시간당',
                '${widget.cafe.reservation.hourlyRate ?? 0}원',
              ),
              _buildInfoItem(
                Icons.access_time,
                '예약 시간',
                '${widget.cafe.reservation.startTime ?? ''} ~ ${widget.cafe.reservation.endTime ?? ''}',
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// 정보 아이템 위젯
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.brown[700]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }



  /// 날짜 섹션
  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '예약 날짜: $_selectedDate',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }



  /// 시작 시간 선택 (TimePicker 사용)
  Widget _buildStartTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '시작 시간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            // 현재 선택된 시간이 있으면 파싱, 없으면 현재 시간 사용
            TimeOfDay initialTime = TimeOfDay.now();
            if (_selectedStartTime != null) {
              final parts = _selectedStartTime!.split(':');
              initialTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }

            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.brown,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    timePickerTheme: const TimePickerThemeData(
                      helpTextStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              final formattedTime =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

              setState(() {
                _selectedStartTime = formattedTime;
                // 시간 변경 시 예약 가능 여부 초기화
                _isAvailable = false;
                _availabilityMessage = null;
              });
              // 시간 변경 시 예약 가능 여부 다시 확인
              if (_selectedDuration != null) {
                _checkAvailability();
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedStartTime ?? '시작 시간을 선택하세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedStartTime != null ? Colors.black : Colors.grey[600],
                    fontFamily: 'Pretendard',
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: Colors.brown[700],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  /// 예약 시간 드롭다운
  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '예약 시간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              hint: const Text('예약 시간을 선택하세요'),
              value: _selectedDuration,
              items: _generateDurationOptions().map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text('$duration시간'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value;
                  // 시간 변경 시 예약 가능 여부 초기화
                  _isAvailable = false;
                  _availabilityMessage = null;
                });
                // 시간 변경 시 예약 가능 여부 다시 확인
                if (_selectedStartTime != null) {
                  _checkAvailability();
                }
              },
            ),
          ),
        ),
      ],
    );
  }



  /// 예약 가능 여부 메시지
  Widget _buildAvailabilityMessage() {
    if (_isCheckingAvailability) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.brown,
              ),
            ),
            SizedBox(width: 12),
            Text('예약 가능 여부 확인 중...'),
          ],
        ),
      );
    }

    if (_availabilityMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAvailable ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAvailable ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.error,
            color: _isAvailable ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _availabilityMessage!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isAvailable ? Colors.green[800] : Colors.red[800],
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }




  /// 결제하기 버튼
  Widget _buildPaymentButton() {
    final bool canProceed = _selectedStartTime != null &&
        _selectedDuration != null &&
        _isAvailable;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canProceed ? Colors.brown : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: canProceed ? _handlePayment : null,
        child: Text(
          canProceed
              ? '결제하기 (${widget.cafe.reservation.hourlyRate ?? 0}원/시간)'
              : '시간을 선택해주세요',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}
