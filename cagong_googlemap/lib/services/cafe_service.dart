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
}
