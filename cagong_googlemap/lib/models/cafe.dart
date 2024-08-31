import 'package:flutter/foundation.dart';

class Cafe {
  final String name;
  final double latitude;
  final double longitude;
  final String message;
  final String address;
  final double hoursWeekday;
  final double hoursWeekend;
  final String price;
  final String videoUrl;
  final String businessHours;
  final List<Seating> seatingTypes;
  final int coWork;
  final double id;
  final Map<String, String> dailyHours;  // New field for daily business hours

  Cafe({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.message = 'No message provided',
    this.address = 'No address provided',
    this.hoursWeekday = -1.0,
    this.hoursWeekend = -1.0,
    this.price = 'Price not available',
    this.videoUrl = '',
    this.businessHours = 'Hours not available',
    required this.seatingTypes,
    this.coWork = 0,
    required this.id,
    required this.dailyHours,  // New parameter
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    List<Seating> seatingList = [];
    for (int i = 1; i <= 5; i++) {
      if (json['Seating Type $i'] != null) {
        seatingList.add(Seating(
          type: json['Seating Type $i'] ?? 'Unknown',
          count: json['Seating Count $i']?.toDouble() ?? 0.0,
          powerCount: json['Power Count $i']?.toString() ?? '0',
        ));
      }
    }

    // Create a map for daily business hours
    Map<String, String> dailyHours = {
      '월': json['월'] ?? 'Not available',
      '화': json['화'] ?? 'Not available',
      '수': json['수'] ?? 'Not available',
      '목': json['목'] ?? 'Not available',
      '금': json['금'] ?? 'Not available',
      '토': json['토'] ?? 'Not available',
      '일': json['일'] ?? 'Not available',
    };

    return Cafe(
      name: json['Name'] ?? 'Unnamed Cafe',
      latitude: json['Position (Latitude)']?.toDouble() ?? 0.0,
      longitude: json['Position (Longitude)']?.toDouble() ?? 0.0,
      message: json['Message'] ?? 'No message provided',
      address: json['Address'] ?? 'No address provided',
      hoursWeekday: json['Hours_weekday']?.toDouble() ?? -1.0,
      hoursWeekend: json['Hours_weekend']?.toDouble() ?? -1.0,
      price: json['Price'] ?? 'Price not available',
      videoUrl: json['Video URL'] ?? '',
      businessHours: json['영업 시간'] ?? 'Hours not available',
      seatingTypes: seatingList,
      coWork: json['Co-work'] ?? 0,
      id: json['ID']?.toDouble() ?? 0.0,
      dailyHours: dailyHours,  // Add the daily hours map
    );
  }
}

class Seating {
  final String type;
  final double count;
  final String powerCount;

  Seating({
    required this.type,
    required this.count,
    required this.powerCount,
  });
}