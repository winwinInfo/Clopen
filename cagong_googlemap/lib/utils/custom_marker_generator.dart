import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../models/cafe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import
import 'marker_generator_web.dart' if (dart.library.io) 'marker_generator_mobile.dart' as platform;

class CustomMarkerGenerator {
  static final Map<String, BitmapDescriptor> _markerCache = {};

  static Future<BitmapDescriptor> createCustomMarker(
    Cafe cafe, {
    double markerSize = 200,
    double fontSize = 18,
    double maxTextWidth = 250,
  }) async {
    //print('Starting createCustomMarker for cafe: ${cafe.name}');

    final String cacheKey = '${cafe.id}_${cafe.coWork}';
    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    final markerImagePath = cafe.coWork == 1 ? 'assets/images/special.png' : 'assets/images/marker.png';
    //print('Creating marker with image path: $markerImagePath');

    final BitmapDescriptor marker = await platform.PlatformMarkerGenerator.generateMarker(
      cafe: cafe,
      markerImagePath: markerImagePath,
      markerSize: markerSize,
      fontSize: fontSize,
      maxTextWidth: maxTextWidth,
    );

    _markerCache[cacheKey] = marker;
    return marker;
  }
}