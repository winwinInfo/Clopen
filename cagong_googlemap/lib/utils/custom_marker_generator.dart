import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/cafe.dart';
import 'dart:math';

class CustomMarkerGenerator {
  static final Map<String, BitmapDescriptor> _markerCache = {};

  static Future<BitmapDescriptor> createCustomMarkerBitmap(
    Cafe cafe, {
    double markerSize = 100,
    double fontSize = 18,
    double maxTextWidth = 150,
  }) async {
    final String cacheKey = '${cafe.id}_${cafe.coWork}';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    try {
      final String markerImagePath =
          cafe.coWork == 1 ? 'assets/images/special.png' : 'assets/images/marker.png';
      final ByteData imageData = await rootBundle.load(markerImagePath);
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: markerSize.round(),
        targetHeight: markerSize.round(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();

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

      final double width = max(fi.image.width.toDouble(), textPainter.width + 8);
      final double height = fi.image.height.toDouble() + textPainter.height + 4;

      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder,
          Rect.fromPoints(const Offset(0, 0), Offset(width, height)));

      final Paint paint = Paint()..isAntiAlias = false;

      final imageLeft = (width - fi.image.width) / 2;
      canvas.drawImage(fi.image, Offset(imageLeft, 0), paint);

      final textLeft = (width - textPainter.width) / 2;
      textPainter.paint(canvas, Offset(textLeft, fi.image.height + 4));
      textPainterInner.paint(canvas, Offset(textLeft, fi.image.height + 4));

      final img = await pictureRecorder
          .endRecording()
          .toImage(width.round(), height.round());

      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      final BitmapDescriptor marker = BitmapDescriptor.fromBytes(
        data!.buffer.asUint8List(),
        size: Size(width, height),
      );

      _markerCache[cacheKey] = marker;
      return marker;
    } catch (e) {
      print('Error creating custom marker: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }
}