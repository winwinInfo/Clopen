import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/cafe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import
import 'marker_generator_web.dart' if (dart.library.io) 'marker_generator_mobile.dart' as platform;

  // 이미지 마커와 텍스트 마커를 함께 반환하기 위한 클래스
  class MarkerPair {
    final BitmapDescriptor imageMarker;
    final BitmapDescriptor textMarker;

    MarkerPair({
      required this.imageMarker,
      required this.textMarker,
    });
  }


class CustomMarkerGenerator {
  static final Map<String, BitmapDescriptor> _imageMarkerCache = {};
  static final Map<String, BitmapDescriptor> _textMarkerCache = {};


  // 이미지 마커와 텍스트 마커를 함께 반환하는 메서드
  static Future<MarkerPair> createCustomMarkers(
    Cafe cafe, {
    double markerSize = 200,
    double fontSize = 18,
    double maxTextWidth = 250,
  }) async {
      print('Starting to create markers for cafe: ${cafe.name}');
    final String cacheKey = '${cafe.id}_${cafe.coWork}';
    
    // 캐시된 마커가 있는지 확인
    if (_imageMarkerCache.containsKey(cacheKey) && 
        _textMarkerCache.containsKey(cacheKey)) {
              print('Using cached markers for cafe: ${cafe.name}');

      return MarkerPair(
        imageMarker: _imageMarkerCache[cacheKey]!,
        textMarker: _textMarkerCache[cacheKey]!,
      );
    }

    final markerImagePath = cafe.coWork == 1 
        ? 'assets/images/special.png' 
        : 'assets/images/marker.png';
  print('Using image path: $markerImagePath');


    // 이미지 마커와 텍스트 마커를 각각 생성
    final imageMarker = await platform.PlatformMarkerGenerator.generateImageMarker(
      markerImagePath: markerImagePath,
      markerSize: markerSize,
    );

    final textMarker = await platform.PlatformMarkerGenerator.generateTextMarker(
      text: cafe.name,
      fontSize: fontSize,
    );
        print('Successfully created text marker');


    // 캐시에 저장
    _imageMarkerCache[cacheKey] = imageMarker;
    _textMarkerCache[cacheKey] = textMarker;

    return MarkerPair(
      imageMarker: imageMarker,
      textMarker: textMarker,
    );
  }
}

