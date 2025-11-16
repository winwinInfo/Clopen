import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cafe.dart';



//카페 마커 생성 클래스 
//마커를 생성하기만 할 뿐, 화면에 그리는 것은 google map 패키지 사용해야함

class CustomMarkerGenerator {

  static Future<BitmapDescriptor> createCustomMarker(
    Cafe cafe, {
    double markerSize = 200,
    double fontSize = 18,
    double maxTextWidth = 250,
  }) async {
    // Use default marker for now (co-work info not available in current API)
    const markerImagePath = 'assets/images/marker.png';

    //mobile marker generation logic
    final BitmapDescriptor marker = await _generateMobileMarker(
      cafe: cafe,
      markerImagePath: markerImagePath,
      markerSize: markerSize,
      fontSize: fontSize,
      maxTextWidth: maxTextWidth,
    );

    return marker;
  }


  static Future<BitmapDescriptor> _generateMobileMarker({
    required Cafe cafe,
    required String markerImagePath,
    required double markerSize,
    required double fontSize,
    required double maxTextWidth,
  }) async {
    print('===== 마커 생성 파라미터 =====');
    print('Cafe: ${cafe.name}');
    print('markerSize: $markerSize');
    print('fontSize: $fontSize');
    print('maxTextWidth: $maxTextWidth');

    final ByteData imageData = await rootBundle.load(markerImagePath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes, targetWidth: markerSize.round(), targetHeight: markerSize.round());
    final ui.FrameInfo fi = await codec.getNextFrame();

    print('실제 이미지 크기: width=${fi.image.width}, height=${fi.image.height}');

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: cafe.name,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Pretendard', // 폰트 명시
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: maxTextWidth);


    // 마커 이미지와 텍스트 중 더 큰 너비를 사용
    final double totalWidth = textPainter.width > markerSize
        ? textPainter.width
        : markerSize;

    final double totalHeight = markerSize + textPainter.height + 8;

    print('최종 캔버스 크기: width=$totalWidth, height=$totalHeight');

    // 마커 이미지를 중앙에 배치
    final double markerX = (totalWidth - markerSize) / 2;
    canvas.drawImage(fi.image, Offset(markerX, 0), Paint());

    // 텍스트를 중앙 정렬 (마커 아래)
    final double textY = markerSize;
    final double textX = (totalWidth - textPainter.width) / 2;
    textPainter.paint(canvas, Offset(textX, textY + 4));

    // Convert to image with explicit pixel ratio
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      totalWidth.round(),
      totalHeight.round(),
    );

    print('생성된 이미지 크기: width=${image.width}, height=${image.height}');

    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}