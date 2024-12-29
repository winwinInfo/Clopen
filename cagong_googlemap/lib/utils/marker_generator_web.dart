import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/cafe.dart';
import 'dart:typed_data';

class PlatformMarkerGenerator {
  static final Map<String, BitmapDescriptor> _markerCache = {};

  static Future<BitmapDescriptor> generateMarker({
    required Cafe cafe,
    required String markerImagePath,
    required double markerSize,
    required double fontSize,
    required double maxTextWidth,
  }) async {
    final String cacheKey = '${cafe.id}_$markerImagePath';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }
    try {
      bool isMobile = (html.window.innerWidth ?? 800) < 600;
      double scaleFactor = isMobile ? 0.7 : 1.0;

      double dpr = (html.window.devicePixelRatio ?? 1.0).toDouble();

      final webImagePath = '${html.window.location.origin}/$markerImagePath';

      final htmlImage = html.ImageElement()
        ..src = webImagePath
        ..crossOrigin = 'anonymous';

      final completer = Completer<BitmapDescriptor>();

      htmlImage.onLoad.listen((_) {
        double adjustedMarkerSize = markerSize * scaleFactor * dpr;
        double adjustedFontSize = fontSize * scaleFactor * dpr;
        final width = (adjustedMarkerSize * 1.8).toInt(); // 마커 너비 증가(글씨 잘려서ㅠ)
        final height = (adjustedMarkerSize + adjustedFontSize + 4).toInt();

        final canvas = html.CanvasElement(width: width, height: height)
          ..style.width = '${width / dpr}px'
          ..style.height = '${height / dpr}px';

        final ctx = canvas.context2D;

        ctx.clearRect(0, 0, width, height);

        // 마커 이미지는 원래 크기로 중앙에 배치
        final imageX = (width - adjustedMarkerSize) / 2;
        ctx.drawImageScaledFromSource(
            htmlImage,
            0,
            0,
            htmlImage.naturalWidth,
            htmlImage.naturalHeight,
            imageX,
            0,
            adjustedMarkerSize,
            adjustedMarkerSize);

        // 텍스트 크기 조정
        final adaptiveFontSize =
            cafe.name.length > 5 ? adjustedFontSize * 0.8 : adjustedFontSize;

        ctx.font = 'bold ${adaptiveFontSize}px Arial';
        ctx.fillStyle = 'black';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.fillText(cafe.name, width / 2, adjustedMarkerSize + 2, width - 10);

        final dataUrl = canvas.toDataUrl('image/png');
        final data = _dataUrlToUint8List(dataUrl);

        final bitmapDescriptor = BitmapDescriptor.fromBytes(data);
        _markerCache[cacheKey] = bitmapDescriptor;

        completer.complete(BitmapDescriptor.fromBytes(data));
      });

      htmlImage.onError.listen((event) {
        completer.completeError('Failed to load image: $webImagePath');
      });

      return completer.future;
    } catch (e) {
      print('Error generating marker: $e');
      rethrow;
    }
  }

  static Uint8List _dataUrlToUint8List(String dataUrl) {
    final splitData = dataUrl.split(',');
    final data = splitData[1];
    return Uint8List.fromList(html.window.atob(data).codeUnits);
  }
}
