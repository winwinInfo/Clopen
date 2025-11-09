import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cafe.dart';



//카페 마커 생성 클래스 
//마커를 생성하기만 할 뿐, 화면에 그리는 것은 google map 패키지 사용해야함



class CustomMarkerGenerator {

  static final Map<String, BitmapDescriptor> _markerCache = {};


  static Future<BitmapDescriptor> createCustomMarker(
    Cafe cafe, {
    double markerSize = 200,
    double fontSize = 18,
    double maxTextWidth = 250,
  }) async {
    // co-work 카페 정보는 일단 뺐음
    final String cacheKey = '${cafe.id}_default';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

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

    _markerCache[cacheKey] = marker;
    return marker;
  }


  static Future<BitmapDescriptor> _generateMobileMarker({
    required Cafe cafe,
    required String markerImagePath,
    required double markerSize,
    required double fontSize,
    required double maxTextWidth,
  }) async {
    final ByteData imageData = await rootBundle.load(markerImagePath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes, targetWidth: markerSize.round(), targetHeight: markerSize.round());
    final ui.FrameInfo fi = await codec.getNextFrame();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    // Draw marker image
    canvas.drawImage(fi.image, Offset.zero, Paint());

    // Draw text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: cafe.name,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxTextWidth);

    print("마커 생성 함수 호출 ! ! @ ! @ ! @  !       @           !");

    final double textY = markerSize;
    final double textX = (markerSize - textPainter.width) / 2;

    // Draw text background
    canvas.drawRect(
      Rect.fromLTWH(0, textY, markerSize, textPainter.height + 8),
      Paint()..color = Colors.white.withOpacity(0.7),
    );

    textPainter.paint(canvas, Offset(textX, textY + 4));

    // Convert to image
    final ui.Image image = await recorder.endRecording().toImage(
      markerSize.round(),
      (markerSize + textPainter.height + 8).round(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
}