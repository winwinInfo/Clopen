import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/cafe.dart';
import 'dart:typed_data';


class PlatformMarkerGenerator {
  static Future<BitmapDescriptor> generateMarker({
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