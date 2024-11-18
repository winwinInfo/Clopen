import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/cafe.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class PlatformMarkerGenerator {
  // 이미지 마커만 생성
  static Future<BitmapDescriptor> generateImageMarker({
    required String markerImagePath,
    required double markerSize,
  }) async {
    final webImagePath = markerImagePath.replaceFirst('assets', '/assets');
    
    final svgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" 
           width="$markerSize" 
           height="$markerSize">
        <image href="$webImagePath" 
               width="$markerSize" 
               height="$markerSize"/>
      </svg>
    ''';

    return _svgToMarker(svgString);
  }

  // 텍스트 마커만 생성
  static Future<BitmapDescriptor> generateTextMarker({
    required String text,
    required double fontSize,
  }) async {
    final svgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" 
           width="${fontSize * text.length * 0.7}" 
           height="${fontSize * 1.2}">
        <text x="50%" 
              y="${fontSize}"
              font-family="Arial, sans-serif" 
              font-size="${fontSize}px" 
              text-anchor="middle" 
              fill="black"
              stroke="white"
              stroke-width="2"
              paint-order="stroke">
          $text
        </text>
      </svg>
    ''';

    return _svgToMarker(svgString);
  }

  // SVG를 마커로 변환하는 헬퍼 메서드
  static Future<BitmapDescriptor> _svgToMarker(String svgString) async {
    final blob = html.Blob([svgString], 'image/svg+xml');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final completer = Completer<BitmapDescriptor>();

    final html.ImageElement img = html.ImageElement()
      ..src = url
      ..style.position = 'absolute'
      ..style.visibility = 'visible'
      ..crossOrigin = 'anonymous';

    img.onLoad.listen((_) {
      final canvas = html.CanvasElement(
        width: img.width,
        height: img.height
      );
      final ctx = canvas.context2D;
      ctx.drawImage(img, 0, 0);
      
      final dataUrl = canvas.toDataUrl('image/png');
      final uint8List = _dataUrlToUint8List(dataUrl);
      
      completer.complete(BitmapDescriptor.fromBytes(uint8List));
    });

    return completer.future;
  }

  static Uint8List _dataUrlToUint8List(String dataUrl) {
    final splitData = dataUrl.split(',');
    final data = splitData[1];
    return Uint8List.fromList(html.window.atob(data).codeUnits);
  }
}