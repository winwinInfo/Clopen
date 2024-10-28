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
    // assets 폴더의 이미지를 웹에서 접근 가능한 경로로 변환
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
          <rect width="100%" height="100%" fill="#FF000050"/>  <!-- 디버깅용 반투명 배경 -->
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


// SVG 문자열 전체 내용 확인
print('Generated SVG content: $svgString');

// Blob 생성 전에 href 속성 확인
print('Image href in SVG: href="$webImagePath"');


    final blob = html.Blob([svgString], 'image/svg+xml');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final completer = Completer<BitmapDescriptor>();

    final html.ImageElement img = html.ImageElement()
      ..src = url
      ..style.position = 'absolute'
      ..style.visibility = 'visible'
      ..crossOrigin = 'anoymous';

          // 이미지 로딩 에러 확인
    img.onError.listen((event) {
      print('Image loading error: $event');
      print('SVG string being used: $svgString');
    });

img.onLoad.listen((_) {
  print('Image loaded successfully');
  print('Image width: ${img.width}');
  print('Image height: ${img.height}');
  
  final canvas = html.CanvasElement(width: img.width, height: img.height);
  final ctx = canvas.context2D;
  
  // Canvas 초기 상태 확인
  print('Canvas created with size: ${canvas.width}x${canvas.height}');
  
  // 배경색으로 Canvas가 제대로 생성되었는지 확인
  ctx.fillStyle = '#FFFF00';  // 노란색 배경
  ctx.fillRect(0, 0, canvas.width!, canvas.height!);
  print('Background drawn');
  
  // drawImage 전후로 Canvas 데이터 확인
  print('Canvas data before drawing: ${canvas.toDataUrl('image/png').length}');
  ctx.drawImage(img, 0, 0);
  print('Image drawn to canvas');
  print('Canvas data after drawing: ${canvas.toDataUrl('image/png').length}');
  

  
  // Canvas 내용을 직접 확인할 수 있도록 임시로 화면에 표시
  canvas.style
    ..position = 'fixed'
    ..top = '0'
    ..left = '0'
    ..zIndex = '9999';
  html.document.body!.append(canvas);
  
  // 잠시 후 Canvas 제거 (디버깅용 표시이므로)
  Future.delayed(Duration(seconds: 2), () {
    canvas.remove();
  });
  
  final dataUrl = canvas.toDataUrl('image/png');
  final uint8List = _dataUrlToUint8List(dataUrl);
  
  print('Final image data length: ${uint8List.length}');
  print('DataURL prefix: ${dataUrl.substring(0, 50)}...'); // 데이터 URL의 시작 부분 확인
  
  completer.complete(BitmapDescriptor.fromBytes(uint8List));
});

    html.document.body!.append(img);
    return completer.future;
  }

  static Uint8List _dataUrlToUint8List(String dataUrl) {
    final splitData = dataUrl.split(',');
    final data = splitData[1];
    return Uint8List.fromList(html.window.atob(data).codeUnits);
  }
}