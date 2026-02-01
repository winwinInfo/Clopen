import 'dart:io';
import 'package:flutter/foundation.dart';

/// API Configuration for different environments and platforms
///
/// This class handles the base URL configuration for API requests
/// depending on the platform (Android/iOS) and build mode (debug/release)
///
/// Usage:
/// - Development: flutter run (debug mode)
/// - Production: flutter run --release (release mode)
/// - Production build: flutter build apk --release
class ApiConfig {
  // 릴리즈 모드일 때 자동으로 production 환경 사용
  // kReleaseMode는 Flutter에서 제공하는 빌드 모드 감지 상수
  static bool get isDevelopment => kDebugMode;

  // Production server URL (PythonAnywhere)
  static const String productionUrl = 'https://yannoo.pythonanywhere.com/api';

  /// Get the appropriate base URL based on platform and environment
  ///
  /// Returns:
  /// - Android Emulator: http://10.0.2.2:5000/api
  /// - iOS Simulator/Real device: http://localhost:5000/api (development)
  /// - Production: Uses productionUrl
  static String get baseUrl {
    if (!isDevelopment) {
      return productionUrl;
    }

    // Development mode: detect platform
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to access host machine's localhost
      return 'http://10.0.2.2:5000/api';
    } else {
      // iOS simulator and other platforms can use localhost directly
      return 'http://localhost:5000/api';
    }
  }

  /// Get full URL for a specific endpoint
  ///
  /// Example:
  /// ```dart
  /// ApiConfig.getUrl('/cafes/') // returns 'http://10.0.2.2:5000/api/cafes/'
  /// ```
  static String getUrl(String endpoint) {
    // Remove leading slash if exists to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }
}
