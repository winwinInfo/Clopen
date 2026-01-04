import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rating.dart';
import '../config/api_config.dart';

class RatingService {

  static Future<RatingStats> getRatingStats(int cafeId, {String? jwtToken}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/ratings/$cafeId');

      final headers = <String, String>{};
      if (jwtToken != null) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          return RatingStats.fromJson(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Rating> submitRating({
    required int cafeId,
    required int rate,
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/ratings/$cafeId');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode({'rate': rate}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          return Rating.fromJson(data['data']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteRating({
    required int cafeId,
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/ratings/$cafeId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $jwtToken'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] != 'SUCCESS') {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyRatings({
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/ratings/my-ratings');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $jwtToken'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          List<dynamic> ratingsJson = data['data'];
          return ratingsJson.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
