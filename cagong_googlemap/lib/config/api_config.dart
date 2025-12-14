import 'dart:io';

/// API Configuration for different environments and platforms
///
/// This class handles the base URL configuration for API requests
/// depending on the platform (Android/iOS) and environment (development/production)
///
/// Usage:
/// - Development: flutter run (기본값)
/// - Production build: flutter build apk --dart-define=ENVIRONMENT=production
/// - Production run: flutter run --dart-define=ENVIRONMENT=production
class ApiConfig {
  // 빌드 타임에 환경 변수로 주입 (기본값: development)
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // 환경 변수 기반으로 개발 모드 자동 판단
  static bool get isDevelopment => _environment == 'development';

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
