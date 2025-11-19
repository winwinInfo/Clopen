import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';
import '../screens/reservation_detail_screen.dart';
import '../services/cafe_service.dart';
import '../models/cafe.dart';

Future<void> reserveSpot(String docId) async {

}

class ReservationScreen extends StatefulWidget {
  final String? cafeId;
  final String? cafeName;

  const ReservationScreen({
    super.key,
    this.cafeId,
    this.cafeName,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // 선택된 카페를 저장하는 변수
  Cafe? _selectedCafe;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.userData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.cafeName ?? '예약',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 타이틀 섹션
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '예약 가능한 카페 목록',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),

            // 예약 가능한 카페 목록
            Expanded(
              child: FutureBuilder<List<Cafe>>(
                // CafeService의 reservationPossibleCafes 함수를 호출
                future: CafeService.reservationPossibleCafes(),
                builder: (context, snapshot) {
                  // 1. 로딩 중인 상태
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.brown,
                      ),
                    );
                  }

                  // 2. 에러가 발생한 상태
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '카페 목록을 불러오는데 실패했습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // 3. 데이터가 없는 상태 (빈 목록)
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.coffee_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '현재 예약 가능한 카페가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 4. 데이터를 성공적으로 받아온 상태
                  final cafes = snapshot.data!;

                  return ListView.builder(
                    itemCount: cafes.length,
                    itemBuilder: (context, index) {
                      final cafe = cafes[index];
                      final isSelected = _selectedCafe?.id == cafe.id;

                      return _buildCafeCard(cafe, isSelected);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 예약 버튼
            if (user != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCafe != null
                        ? Colors.brown
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed:
                      _selectedCafe != null ? () => _makeReservation() : null,
                  child: Text(
                    _selectedCafe != null
                        ? '${_selectedCafe!.name} 예약하기'
                        : '카페를 선택해주세요',
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    const Text(
                      '예약하려면 로그인이 필요합니다.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: const Text('로그인하기'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }





  /// 카페 카드 위젯을 생성하는 메서드
  Widget _buildCafeCard(Cafe cafe, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.brown : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            // 선택된 카페를 저장 (이미 선택된 카페를 다시 클릭하면 선택 해제)
            _selectedCafe = isSelected ? null : cafe;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카페 이름과 선택 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cafe.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                        color: isSelected ? Colors.brown : Colors.black,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.brown,
                      size: 28,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 주소
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cafe.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 예약 정보 섹션
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // 예약 시간
                    if (cafe.reservation.startTime != null &&
                        cafe.reservation.endTime != null)
                      _buildInfoRow(
                        Icons.access_time,
                        '예약 시간',
                        '${cafe.reservation.startTime} - ${cafe.reservation.endTime}',
                      ),

                    // 시간당 요금
                    if (cafe.reservation.hourlyRate != null)
                      _buildInfoRow(
                        Icons.attach_money,
                        '시간당 요금',
                        '${cafe.reservation.hourlyRate}원',
                      ),

                    // 총 좌석 수
                    if (cafe.reservation.totalSeats != null)
                      _buildInfoRow(
                        Icons.event_seat,
                        '총 좌석',
                        '${cafe.reservation.totalSeats}석',
                      ),

                    // 콘센트 수
                    if (cafe.reservation.totalConsents != null)
                      _buildInfoRow(
                        Icons.power,
                        '콘센트',
                        '${cafe.reservation.totalConsents}개',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 정보 행을 생성하는 헬퍼 메서드
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.brown[700]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



  void _makeReservation() {
    if (_selectedCafe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카페를 선택해주세요')),
      );
      return;
    }

    // 예약 상세 화면으로 네비게이션
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservationDetailScreen(
          cafe: _selectedCafe!,
        ),
      ),
    );
  }
}