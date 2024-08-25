import 'package:flutter/material.dart';

class BottomSheetContent extends StatelessWidget {
  final String name;
  final String message;
  final String address;
  final String price;
  final String hours;
  final String videoUrl;
  final List<Map<String, dynamic>> seatingInfo;

  BottomSheetContent({
    required this.name,
    required this.message,
    required this.address,
    required this.price,
    required this.hours,
    required this.videoUrl,
    required this.seatingInfo,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.25, // 바텀 시트의 초기 크기
      maxChildSize: 0.8,      // 바텀 시트가 확장될 수 있는 최대 크기
      minChildSize: 0.1,      // 바텀 시트가 최소한으로 보여지는 크기
      expand: true,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text("주소: $address", style: TextStyle(fontSize: 14)),
                Text("가격: $price", style: TextStyle(fontSize: 14)),
                Text("영업 시간: $hours", style: TextStyle(fontSize: 14)),
                SizedBox(height: 10),
                ...seatingInfo.map((seating) {
                  return Text(
                    "${seating['type']}석 - ${seating['count']}석 (콘센트: ${seating['power']})",
                    style: TextStyle(fontSize: 14),
                  );
                }).toList(),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    print("영상 링크 열기: $videoUrl");
                  },
                  child: Text(
                    "영상 보기",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
