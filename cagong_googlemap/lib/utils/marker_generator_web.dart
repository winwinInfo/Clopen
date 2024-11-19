import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
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
    try {
      final webImagePath = html.window.location.origin + '/' + markerImagePath.replaceFirst('assets', 'assets');
      
      final htmlImage = html.ImageElement()
        ..src = webImagePath
        ..crossOrigin = 'anonymous';

      final completer = Completer<BitmapDescriptor>();
      
      htmlImage.onLoad.listen((_) {
        final width = (markerSize * 1.8).toInt(); // 마커 너비 증가(글씨 잘려서ㅠ)
        final height = (markerSize + fontSize + 4).toInt();
        
        final canvas = html.CanvasElement(width: width, height: height)
          ..style.width = '${width}px'
          ..style.height = '${height}px';
        
        final ctx = canvas.context2D;
        
        ctx.clearRect(0, 0, width, height);
        
        // 마커 이미지는 원래 크기로 중앙에 배치
        final imageX = (width - markerSize) / 2;
        ctx.drawImageScaledFromSource(
          htmlImage,
          0, 0, htmlImage.naturalWidth!, htmlImage.naturalHeight!,
          imageX, 0, markerSize, markerSize
        );
        
        // 텍스트 크기 조정
        final adaptiveFontSize = cafe.name.length > 5 ? fontSize * 0.8 : fontSize;

        ctx.font = 'bold ${adaptiveFontSize}px Arial';
        ctx.fillStyle = 'black';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'top';
        ctx.fillText(cafe.name, width / 2, markerSize + 2, width - 10);
        
        final dataUrl = canvas.toDataUrl('image/png');
        final data = _dataUrlToUint8List(dataUrl);
        
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