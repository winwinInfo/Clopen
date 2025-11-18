import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';

Future<void> reserveSpot(String docId) async {
  // Firebase 기능 비활성화 - 임시 처리
  debugPrint('예약 기능은 현재 비활성화되어 있습니다.');
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
            // 예약 현황 
            Expanded(
              child: Center(
                child: Text(
                  '예약 기능은 현재 비활성화되어 있습니다.\n(Flask 연결 후 다시 활성화됩니다)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 예약 버튼
            if (user != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _makeReservation(),
                  child: const Text('예약하기'),
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



  void _makeReservation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 기능은 현재 비활성화되어 있습니다')),
    );
  }
}