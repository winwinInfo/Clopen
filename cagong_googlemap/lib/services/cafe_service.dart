import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cafe.dart';
import '../config/api_config.dart';


class CafeService {


  /// Fetch all cafes from the backend
  ///
  /// Returns a list of [Cafe] objects
  /// Throws an [Exception] if the request fails
  static Future<List<Cafe>> getAllCafes() async {
    try {
      // Build the API endpoint URL
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/');

      // Send GET request to the server
      final response = await http.get(uri);
      print('겟 올 카페s Response Status Code: ${response.statusCode}');

      // Check if the request was successful (HTTP 200)
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<dynamic> cafesJson = data['data'];

          // Convert each JSON object to a Cafe model instance
          return cafesJson.map((json) => Cafe.fromJson(json)).toList();
        } else {
          // API returned success: false
          throw Exception('API Response Failed: ${data['error']}');
        }
      } else {
        // HTTP error (404, 500, etc.)
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      // Log error and re-throw to caller
      print('Error loading cafe data: $e');
      rethrow;
    }
  }


  /// Fetch a specific cafe by ID
  ///
  /// [cafeId]: The ID of the cafe to fetch
  /// Returns a [Cafe] object
  /// Throws an [Exception] if the cafe is not found or request fails
  /// 
  static Future<Cafe> getCafeById(int cafeId) async {
    try {
      // Build the API endpoint URL with cafe ID
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/$cafeId');

      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Convert JSON to Cafe object
        return Cafe.fromJson(data['data']);
      } else {
        // Cafe not found or other error
        throw Exception(data['error'] ?? 'Cafe not found');
      }
    } catch (e) {
      print('Error fetching cafe: $e');
      rethrow;
    }
  }

  
  static Future<Cafe> getCafeNameById(int cafeId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/$cafeId/name');
      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return Cafe.fromJson(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Cafe not found');
      }
    } catch (e) {
      print('Error fetching cafe name: $e');
      rethrow;
    }
  }



  /// Fetch reservation-enabled cafes from the backend
  ///
  /// Returns a list of [Cafe] objects that have reservation enabled
  /// Throws an [Exception] if the request fails
  static Future<List<Cafe>> reservationPossibleCafes() async {
    try {
      // Build the API endpoint URL
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/reservation-possible');

      // Send GET request to the server with timeout
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      print('예약 가능 카페 Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<dynamic> cafesJson = data['data'];

          // Convert each JSON object to a Cafe model instance
          return cafesJson.map((json) => Cafe.fromJson(json)).toList();
        } else {
          // API returned success: false
          throw Exception('API Response Failed: ${data['error']}');
        }
      } else {
        // HTTP error (404, 500, etc.)
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      // Log error and re-throw to caller
      print('Error loading reservable cafes: $e');
      rethrow;
    }
  }


  /// Search cafes using Google Places API
  ///
  /// [query]: Search query (e.g., "스타벅스 강남")
  /// [latitude]: Optional center point latitude
  /// [longitude]: Optional center point longitude
  /// [radius]: Optional search radius in meters
  ///
  /// Returns a list of search results from Places API
  /// Each result contains: place_id, name, latitude, longitude
  static Future<List<Map<String, dynamic>>> searchCafesFromPlaces({
    required String query,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/search');

      // Prepare request body (Map<String, dynamic>으로 명시적 선언)
      final Map<String, dynamic> requestBody = {
        'query': query,
      };

      // Add optional location parameters (double 값을 그대로 저장)
      if (latitude != null && longitude != null) {
        requestBody['latitude'] = latitude;
        requestBody['longitude'] = longitude;
      }

      if (radius != null) {
        requestBody['radius'] = radius;
      }

      // Send POST request
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      print('Places 검색 Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<dynamic> cafesJson = data['data'];
          return cafesJson.cast<Map<String, dynamic>>();
        } else {
          throw Exception('API Response Failed: ${data['error']}');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching cafes from Places API: $e');
      rethrow;
    }
  }


  /// Add a cafe from Google Places search result to the database
  ///
  /// [name]: Cafe name
  /// [address]: Cafe address
  /// [latitude]: Latitude
  /// [longitude]: Longitude
  ///
  /// Returns a Map containing success status and message/data
  static Future<Map<String, dynamic>> addCafeFromPlaces({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/cafes/add-from-places');

      // Prepare request body (Map<String, dynamic>으로 명시적 선언)
      final Map<String, dynamic> requestBody = {
        'name': name,
        'address': address,
        'latitude': latitude,  // double 값을 그대로 저장 (정밀도 보존)
        'longitude': longitude,  // double 값을 그대로 저장 (정밀도 보존)
      };

      // Send POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      print('카페 추가 Response Status Code: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Success (201 Created)
        return {
          'success': true,
          'message': data['message'] ?? '카페가 추가되었습니다.',
          'data': data['data'],
        };
      } else if (response.statusCode == 400) {
        // Bad request (validation error or duplicate)
        final errorMessage = data['error'] ?? '카페 추가에 실패했습니다.';

        // 중복 카페 여부 판단 (에러 메시지에 "이미 등록" 포함 여부)
        final isDuplicate = errorMessage == 'duplicated';

        return {
          'success': false,
          'error': errorMessage,
          'isDuplicate': isDuplicate,
        };
      } else {
        // Other errors
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding cafe: $e');
      rethrow;
    }
  }
}
