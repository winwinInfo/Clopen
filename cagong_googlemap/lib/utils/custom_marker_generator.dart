import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cafe.dart';

class CustomMarkerGenerator {
  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    Cafe cafe, {
    double imageScale = 0.5,
    double titleFontSize = 16,
    double subtitleFontSize = 12,
  }) async {
    // 마커 이미지 로드
        // 마커 이미지 로드 (Co-work 값에 따라 다른 이미지 사용)
    final String markerImagePath = cafe.coWork == 1
        ? 'images/special.png'
        : 'images/marker.png';
    final ByteData imageData =
        await rootBundle.load(markerImagePath);
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 100,
      targetHeight: 100,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();

    // 이미지 크기 조절
    final int newWidth = (fi.image.width * imageScale).round();
    final int newHeight = (fi.image.height * imageScale).round();
    final ui.Image resizedImage =
        await _resizeImage(fi.image, newWidth, newHeight);

    // 캔버스 설정
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 크기 조절된 마커 이미지 그리기
    canvas.drawImage(resizedImage, Offset.zero, Paint());

    // 텍스트 영역 크기 계산 (텍스트 크기에 따라 조정)
    final double textAreaHeight =
        (titleFontSize + subtitleFontSize * 2 + 20).ceil().toDouble();
    const double textAreaWidth = 180.0;

    // 텍스트 배경 그리기
    final Paint bgPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawRect(
        Rect.fromLTWH(0, newHeight.toDouble(), textAreaWidth, textAreaHeight),
        bgPaint);

    // 텍스트 그리기를 위한 TextPainter 설정
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaleFactor: 1.0, // 텍스트 스케일 팩터 추가
    );

    // 카페 이름 그리기
    textPainter.text = TextSpan(
      text: cafe.name,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Roboto', // 폰트 지정
      ),
    );
    textPainter.layout(maxWidth: textAreaWidth);
    textPainter.paint(canvas, Offset(5, newHeight.toDouble() + 5));

    // 평일 영업 시간 그리기
    textPainter.text = TextSpan(
      text: 'Weekday: ${cafe.hoursWeekday}',
      style: TextStyle(
        fontSize: subtitleFontSize,
        color: Colors.black,
        fontFamily: 'Roboto', // 폰트 지정
      ),
    );
    textPainter.layout(maxWidth: textAreaWidth);
    textPainter.paint(
        canvas, Offset(5, newHeight.toDouble() + titleFontSize + 10));

    // 주말 영업 시간 그리기
    textPainter.text = TextSpan(
      text: 'Weekend: ${cafe.hoursWeekend}',
      style: TextStyle(
        fontSize: subtitleFontSize,
        color: Colors.black,
        fontFamily: 'Roboto', // 폰트 지정
      ),
    );
    textPainter.layout(maxWidth: textAreaWidth);
    textPainter.paint(
        canvas,
        Offset(
            5, newHeight.toDouble() + titleFontSize + subtitleFontSize + 15));

    // 캔버스에 그린 내용을 이미지로 변환
    final ui.Image img = await pictureRecorder
        .endRecording()
        .toImage(textAreaWidth.round(), (newHeight + textAreaHeight).round());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);

    // 이미지를 BitmapDescriptor로 변환하여 반환
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // 이미지 크기 조절 함수
  static Future<ui.Image> _resizeImage(
      ui.Image image, int width, int height) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
    final ui.Image resizedImage =
        await pictureRecorder.endRecording().toImage(width, height);
    return resizedImage;
  }
}
