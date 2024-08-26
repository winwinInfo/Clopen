import 'package:cagong_googlemap/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import '../models/cafe.dart';
import 'package:cagong_googlemap/screens/map_screen.dart';


Future<BitmapDescriptor> resizeMarkerImage(
    String assetPath, int width, int height) async {
  // 1. 에셋에서 이미지 바이트 로드
  ByteData data = await rootBundle.load(assetPath);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  ui.FrameInfo fi = await codec.getNextFrame();

  // 2. 이미지 리사이즈
  img.Image image = img.decodeImage(data.buffer.asUint8List())!;
  img.Image resizedImage = img.copyResize(image, width: width, height: height);

  // 3. 리사이즈된 이미지를 Uint8List로 변환
  Uint8List resizedImageData = Uint8List.fromList(img.encodePng(resizedImage));

  // 4. BitmapDescriptor 생성 및 반환
  return BitmapDescriptor.fromBytes(resizedImageData);
}

Future<Set<Marker>> createMarkers(List<Cafe> cafes, Function(Cafe) onTap) async {
  // 커스텀 마커 아이콘 로드 및 리사이즈
  BitmapDescriptor customIcon =
      await resizeMarkerImage('images/marker.png', 25, 25);

  // Cafe 리스트를 순회하며 마커 생성
  Set<Marker> markers = cafes.map((cafe) {
    return Marker(
      markerId: MarkerId(cafe.id.toString()),
      position: LatLng(cafe.latitude, cafe.longitude),
      infoWindow: InfoWindow(
        title: cafe.name,
        snippet: cafe.message,
      ),
      icon: customIcon,
      onTap: () {
        onTap(cafe);// 리사이즈된 커스텀 마커 아이콘 설정
      }
    );
  }).toSet();

  return markers;
}
