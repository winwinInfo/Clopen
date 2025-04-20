import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';

Future<void> reserveSpot(String docId) async {
  final docRef = FirebaseFirestore.instance.collection('reservations').doc(docId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    final data = snapshot.data() as Map<String, dynamic>;

    int current = data['currentPeople'] ?? 0;
    int max = data['maxPeople'] ?? 1;

    if (current < max) {
      current += 1;
      String newStatus = current >= (max * 0.6) ? '마감임박!' : '예약가능';

      transaction.update(docRef, {
        'currentPeople': current,
        'status': newStatus,
      });
    } else {
      print('자리가 없습니다!');
    }
  });
}

class ReservationScreen extends StatelessWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthProvider에서 현재 사용자 정보 가져오기
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 리스트'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      // 사용자 로그인 여부에 따라 다른 화면 표시
      body: user != null
          ? _buildReservationList()
          : _buildLoginPrompt(context),
    );
  }

  // 로그인하지 않은 사용자를 위한 화면
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '예약을 보려면 로그인이 필요합니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '로그인하기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 로그인한 사용자를 위한 예약 목록 화면
  Widget _buildReservationList() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reservations')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData) {
                return const Center(child: Text('예약 정보 없음'));
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;

                  return ReservationCard(
                    docId: docId,
                    time: data['time'],
                    place: data['place'],
                    status: data['status'],
                    currentPeople: data['currentPeople'],
                    maxPeople: data['maxPeople'],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReservationCard extends StatelessWidget {
  final String docId;
  final String time;
  final String place;
  final String status;
  final int currentPeople;
  final int maxPeople;

  const ReservationCard({
    super.key,
    required this.docId,
    required this.time,
    required this.place,
    required this.status,
    required this.currentPeople,
    required this.maxPeople,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = status == '마감임박!';
    final isFull = currentPeople >= maxPeople;

    // 현재 사용자 정보 가져오기
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.user; // 로그인 여부 확인은 이미 상위 위젯에서 처리되므로 여기서는 버튼 기능만 처리

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽 정보 (Column)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time | $place',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$currentPeople / $maxPeople명 예약됨'),
              ],
            ),

            // 오른쪽 버튼
            ElevatedButton(
              onPressed: isFull ? null : () => reserveSpot(docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull
                    ? Colors.grey
                    : (isUrgent ? Colors.red : Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isFull ? '마감' : status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}