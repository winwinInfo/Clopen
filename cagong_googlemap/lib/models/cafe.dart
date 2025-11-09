import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 카페 모델 - Flask API 응답과 매칭
class Cafe {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? message;
  final int? hoursWeekday;
  final int? hoursWeekend;
  final String? price;
  final String? videoUrl;
  final String? lastOrder;
  final OperatingHours operatingHours;
  final ReservationInfo reservation;

  Cafe({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.message,
    this.hoursWeekday,
    this.hoursWeekend,
    this.price,
    this.videoUrl,
    this.lastOrder,
    required this.operatingHours,
    required this.reservation,
  });

  /// Flask API JSON 응답에서 Cafe 객체 생성
  factory Cafe.fromJson(Map<String, dynamic> json) {
    return Cafe(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Cafe',
      address: json['address'] ?? 'No address',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      message: json['message'],
      hoursWeekday: json['hours_weekday'],
      hoursWeekend: json['hours_weekend'],
      price: json['price'],
      videoUrl: json['video_url'],
      lastOrder: json['last_order'],
      operatingHours: OperatingHours.fromJson(json['operating_hours'] ?? {}),
      reservation: ReservationInfo.fromJson(json['reservation'] ?? {}),
    );
  }

  /// 구글맵 LatLng 객체로 변환
  LatLng get location => LatLng(latitude, longitude);
}

/// 운영 시간 정보
class OperatingHours {
  final DayHours? monday;
  final DayHours? tuesday;
  final DayHours? wednesday;
  final DayHours? thursday;
  final DayHours? friday;
  final DayHours? saturday;
  final DayHours? sunday;
  final String? description;

  OperatingHours({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
    this.description,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      monday: json['monday'] != null ? DayHours.fromJson(json['monday']) : null,
      tuesday: json['tuesday'] != null ? DayHours.fromJson(json['tuesday']) : null,
      wednesday: json['wednesday'] != null ? DayHours.fromJson(json['wednesday']) : null,
      thursday: json['thursday'] != null ? DayHours.fromJson(json['thursday']) : null,
      friday: json['friday'] != null ? DayHours.fromJson(json['friday']) : null,
      saturday: json['saturday'] != null ? DayHours.fromJson(json['saturday']) : null,
      sunday: json['sunday'] != null ? DayHours.fromJson(json['sunday']) : null,
      description: json['description'],
    );
  }

  /// 오늘의 운영시간 가져오기
  DayHours? getTodayHours() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return monday;
      case DateTime.tuesday:
        return tuesday;
      case DateTime.wednesday:
        return wednesday;
      case DateTime.thursday:
        return thursday;
      case DateTime.friday:
        return friday;
      case DateTime.saturday:
        return saturday;
      case DateTime.sunday:
        return sunday;
      default:
        return null;
    }
  }
}

/// 하루 운영 시간
class DayHours {
  final String? begin;
  final String? end;

  DayHours({this.begin, this.end});

  factory DayHours.fromJson(Map<String, dynamic> json) {
    return DayHours(
      begin: json['begin'],
      end: json['end'],
    );
  }

  /// 운영시간 문자열 반환 (예: "09:00 - 22:00")
  String toDisplayString() {
    if (begin == null || end == null) return '정보 없음';
    return '$begin - $end';
  }
}

/// 예약 정보
class ReservationInfo {
  final bool enabled;
  final int? totalSeats;
  final int? totalConsents;
  final String? startTime;
  final String? endTime;
  final int? hourlyRate;

  ReservationInfo({
    required this.enabled,
    this.totalSeats,
    this.totalConsents,
    this.startTime,
    this.endTime,
    this.hourlyRate,
  });

  factory ReservationInfo.fromJson(Map<String, dynamic> json) {
    return ReservationInfo(
      enabled: json['enabled'] ?? false,
      totalSeats: json['total_seats'],
      totalConsents: json['total_consents'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      hourlyRate: json['hourly_rate'],
    );
  }
}
