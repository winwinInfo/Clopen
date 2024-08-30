import 'package:flutter/material.dart';
import '../models/cafe.dart';

class DetailScreen extends StatelessWidget {
  final Cafe cafe;

  const DetailScreen({Key? key, required this.cafe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cafe.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cafe.message, style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text("주소: ${cafe.address}"),
              Text("가격: ${cafe.price}"),
              Text("평일 이용 시간: ${cafe.hoursWeekday}"),
              Text("주말 이용 시간: ${cafe.hoursWeekend}"),
              SizedBox(height: 20),
              Text("좌석 정보:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...cafe.seatingTypes.map((seating) => Padding(
                    padding: const EdgeInsets.only(left: 10.0, top: 5.0),
                    child: Text(
                        "${seating.type}석 - ${seating.count}석 (콘센트: ${seating.powerCount})"),
                  )),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement video playback
                  print("영상 재생: ${cafe.videoUrl}");
                },
                child: Text("영상 보기"),
              ),
              // TODO: Add more detailed information and features as needed
            ],
          ),
        ),
      ),
    );
  }
}
