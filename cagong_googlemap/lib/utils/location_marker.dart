import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;

class LocationMarkerService {
  // 싱글톤 패턴 구현
  static final LocationMarkerService _instance = LocationMarkerService._internal();
  factory LocationMarkerService() => _instance;
  LocationMarkerService._internal();

  // 마커 아이콘 캐싱
  BitmapDescriptor? _circleMarker;

  // 위치 추적을 위한 스트림 구독
  StreamSubscription<Position>? _positionStreamSubscription;

  // 현재 위치 마커와 콜백
  Marker? currentLocationMarker;
  Function(Marker)? onMarkerUpdate;

  // 마커 초기화 메서드
  Future<void> initializeCircleMarker() async {
    _circleMarker ??= await _createCircleMarker(Colors.red, 20);
  }

  // 원형 마커 생성
  Future<BitmapDescriptor> _createCircleMarker(Color color, double size) async {
    // 디바이스 픽셀 비율 가져오기
    final dpr = WidgetsBinding.instance.window.devicePixelRatio;

    // 크기를 픽셀 비율로 조정
    final adjustedSize = size / dpr;
    final borderWidth = 3 / dpr;  // 테두리 두께도 조정

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 하얀색 테두리 Paint 객체
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 컬러 원 Paint 객체
    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 하얀색 테두리 원
    canvas.drawCircle(
        Offset(adjustedSize / 2, adjustedSize / 2),
        adjustedSize / 2,
        borderPaint
    );

    // 컬러 원 (테두리 안쪽)
    canvas.drawCircle(
        Offset(adjustedSize / 2, adjustedSize / 2),
        adjustedSize / 2 - borderWidth,
        circlePaint
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(adjustedSize.toInt(), adjustedSize.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // 마커 아이콘 가져오기
  BitmapDescriptor getCircleMarker() {
    if (_circleMarker == null) {
      throw Exception(
          "Circle marker not initialized. Call initializeCircleMarker() first.");
    }
    return _circleMarker!;
  }

  // 현재 위치 가져오기
  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      updateCurrentLocationMarker(position);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // 위치 추적 시작
  void startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      updateCurrentLocationMarker(position);
    });
  }

  // 위치 추적 중지
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // 현재 위치 마커 업데이트
  void updateCurrentLocationMarker(Position position) {
    final LatLng location = LatLng(position.latitude, position.longitude);

    currentLocationMarker = Marker(
      markerId: const MarkerId('current_location'),
      position: location,
      icon: getCircleMarker(),
      infoWindow: const InfoWindow(title: '현재 위치'),
      zIndex: 100.0,
    );

    // 콜백을 통해 마커 업데이트를 알림
    if (onMarkerUpdate != null) {
      onMarkerUpdate!(currentLocationMarker!);
    }
  }

  // 현재 위치 반환
  LatLng? getCurrentPosition() {
    return currentLocationMarker?.position;
  }

  // 자원 해제
  void dispose() {
    stopLocationTracking();
  }
}