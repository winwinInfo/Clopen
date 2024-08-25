import 'package:flutter/material.dart';

class BottomSheetContent extends StatelessWidget {
  final String name;
  final String message;
  final String address;
  final String price;
  final String hours;
  final String videoUrl;

  BottomSheetContent({
    required this.name,
    required this.message,
    required this.address,
    required this.price,
    required this.hours,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      height: 250,
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
          Text(
            "Address: $address",
            style: TextStyle(fontSize: 14),
          ),
          Text(
            "Price: $price",
            style: TextStyle(fontSize: 14),
          ),
          Text(
            "Hours: $hours",
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              // 여기에 유튜브 URL을 열거나 다른 행동을 할 수 있습니다.
              print("Open video URL: $videoUrl");
            },
            child: Text(
              "Watch Video",
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}