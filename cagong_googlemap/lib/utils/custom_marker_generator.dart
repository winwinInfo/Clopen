import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cafe.dart';
import 'dart:math';

class CustomMarkerGenerator {
  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    Cafe cafe, {
    double markerSize = 100,
    double fontSize = 18,
    double maxTextWidth = 150,
  }) async {
    // 마커 이미지 로드 및 리사이징
    final String markerImagePath =
        cafe.coWork == 1 ? 'images/special.png' : 'images/marker.png';
    final ByteData imageData = await rootBundle.load(markerImagePath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: markerSize.round(),
      targetHeight: markerSize.round(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();

    // 텍스트 페인터 설정 (테두리 포함)
    final textPainter = TextPainter(
      text: TextSpan(
        text: cafe.name,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    textPainter.layout(maxWidth: maxTextWidth);

    // 텍스트 내부 색상을 위한 두 번째 TextPainter
    final textPainterInner = TextPainter(
      text: TextSpan(
        text: cafe.name,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    textPainterInner.layout(maxWidth: maxTextWidth);

    // 캔버스 크기 계산
    final double width = max(fi.image.width.toDouble(), textPainter.width + 8);
    final double height = fi.image.height.toDouble() + textPainter.height + 4;

    // 캔버스 생성
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder,
        Rect.fromPoints(const Offset(0, 0), Offset(width, height)));

    // 안티앨리어싱 비활성화
    final Paint paint = Paint()..isAntiAlias = false;

    // 이미지 그리기 (중앙 정렬)
    final imageLeft = (width - fi.image.width) / 2;
    canvas.drawImage(fi.image, Offset(imageLeft, 0), paint);

    // 텍스트 그리기 (테두리, 중앙 정렬)
    final textLeft = (width - textPainter.width) / 2;
    textPainter.paint(canvas, Offset(textLeft, fi.image.height + 4));

    // 텍스트 그리기 (내부 색상, 중앙 정렬)
    textPainterInner.paint(canvas, Offset(textLeft, fi.image.height + 4));

    // 비트맵 생성
    final img = await pictureRecorder
        .endRecording()
        .toImage(width.round(), height.round());

    // BitmapDescriptor 생성
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(
      data!.buffer.asUint8List(),
      size: Size(width, height),
    );
  }
}
