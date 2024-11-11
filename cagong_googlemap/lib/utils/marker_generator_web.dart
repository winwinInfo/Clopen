import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/cafe.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class PlatformMarkerGenerator {
  static Future<BitmapDescriptor> generateMarker({
    required Cafe cafe,
    required String markerImagePath,
    required double markerSize,
    required double fontSize,
    required double maxTextWidth,
  })  async {
    //assets 폴더의 이미지를 웹에서 접근 가능한 경로로 변환
  final webImagePath = markerImagePath.replaceFirst('assets', '/assets');
  //final webImagePath = '/assets/images/marker.png';

  print('Attempting to load image from: $webImagePath');
  
  // 텍스트를 위한 여백
  final textPadding = 16.0;  // 상하 여백
  final horizontalPadding = 24.0;  // 좌우 여백
  
  // SVG 전체 너비를 마커보다 크게 설정
  final svgWidth = markerSize * 3;  // 또는 더 큰 값으로 조정
  final svgHeight = markerSize + fontSize + textPadding;
  
  // 마커 이미지의 x 오프셋 계산 (중앙 정렬을 위해)
  final imageXOffset = (svgWidth - markerSize) / 2;

  final svgString = '''
    <svg xmlns="http://www.w3.org/2000/svg" 
         width="$svgWidth" 
         height="$svgHeight">
      <image href="$webImagePath" 
             x="$imageXOffset"
             width="$markerSize" 
             height="$markerSize"/>
      <text x="${svgWidth / 2}" 
            y="${markerSize + (textPadding/2)}" 
            font-family="Arial, sans-serif" 
            font-size="${fontSize}px" 
            font-weight="bold" 
            text-anchor="middle" 
            fill="black" 
            stroke="white"
            stroke-width="2"
            paint-order="stroke"
            style="pointer-events: none;">
        ${cafe.name}
      </text>
    </svg>
  ''';

    final blob = html.Blob([svgString], 'image/svg+xml');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final completer = Completer<BitmapDescriptor>();

    final html.ImageElement img = html.ImageElement()
      ..src = url
      ..style.position = 'absolute'
      ..style.visibility = 'visible'
      ..crossOrigin = 'anonymous';



img.onLoad.listen((_) {

  final canvas = html.CanvasElement(width: img.width, height: img.height);
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