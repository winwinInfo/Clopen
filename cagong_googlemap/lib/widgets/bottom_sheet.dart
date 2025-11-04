import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cafe.dart'; // Cafe 모델이 정의된 파일
import '../screens/detail_screen.dart'; // DetailScreen이 정의된 파일

class CafeBottomSheet extends StatelessWidget {
  final Cafe cafe;

  const CafeBottomSheet({super.key, required this.cafe});

  String _getUsageTimeText(int? hours) {
    if (hours == null || hours == -1) return '무제한';
    if (hours == 0) return '권장X';
    return '$hours 시간';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailScreen(cafe: cafe)),
        );
      },
      child: Container(
        height: 200,
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cafe.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildOpenStatusChip(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  cafe.message ?? '정보 없음',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "평일 이용 시간: ${_getUsageTimeText(cafe.hoursWeekday)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "주말 이용 시간: ${_getUsageTimeText(cafe.hoursWeekend)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.brown,
                  ),
                  child: const Text(
                    '더보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getOpenStatus() {
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);

    final todayHours = cafe.operatingHours.getTodayHours();

    if (todayHours == null || todayHours.begin == null || todayHours.end == null) {
      return '휴무일';
    }

    String openTime = todayHours.begin!;
    String closeTime = todayHours.end!;

    if (_isTimeBetween(currentTime, openTime, closeTime)) {
      return '영업중';
    } else {
      return '영업 종료';
    }
  }

  Widget _buildOpenStatusChip() {
    String status = _getOpenStatus();
    Color statusColor;
    switch (status) {
      case '영업중':
        statusColor = Colors.green;
        break;
      case '영업 종료':
        statusColor = Colors.grey;
        break;
      case '휴무일':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blue;
    }
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      side: const BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
      backgroundColor: statusColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // 원하는 둥근 정도로 조절 가능
      ),
    );
  }


  bool _isTimeBetween(String current, String open, String close) {
    int currentMinutes = _timeToMinutes(current);
    int openMinutes = _timeToMinutes(open);
    int closeMinutes = _timeToMinutes(close);

    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    } else {
      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    }
  }

  int _timeToMinutes(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
