import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:ui' as ui;

class CurrentLocationButton extends StatelessWidget {
  final Function(Marker) onLocationFound;

  const CurrentLocationButton({Key? key, required this.onLocationFound})
      : super(key: key);

  // 이미지를 로드하고 크기를 조정한 후 BitmapDescriptor로 반환하는 함수
  Future<BitmapDescriptor> _createResizedMarkerImageFromAsset(
      String assetName, int width) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final data2 = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data2!.buffer.asUint8List());
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 권한이 거부된 경우 처리
          return;
        }
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng location = LatLng(position.latitude, position.longitude);

      // 현재 위치 마커 생성 (크기 조정된 아이콘 사용)
      final BitmapDescriptor markerIcon =
          await _createResizedMarkerImageFromAsset(
              'images/current_location_marker.png', 35); // 원하는 크기로 조정
      Marker currentLocationMarker = Marker(
        markerId: MarkerId('current_location'),
        position: location,
        icon: markerIcon,
        infoWindow: InfoWindow(title: '현재 위치'),
      );

      // 마커를 호출한 곳에 전달
      onLocationFound(currentLocationMarker);
    } catch (e) {
      print('Error getting current location: $e');
      // 에러 처리 로직을 추가할 수 있습니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.my_location),
      onPressed: _getCurrentLocation,
    );
  }
}
