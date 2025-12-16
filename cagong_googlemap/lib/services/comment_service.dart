import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import '../config/api_config.dart';


class CommentService {
  static Future<List<Comment>> getComments(int cafeId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments/$cafeId');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          List<dynamic> commentsJson = data['data'];
          return commentsJson.map((json) => Comment.fromJson(json)).toList();
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



  static Future<Comment> createComment({
    required int cafeId,
    required String content,
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments/$cafeId');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode({'content': content}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          return Comment.fromJson(data['data']);
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



  static Future<void> deleteComment({
    required int commentId,
    required String jwtToken,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments/$commentId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $jwtToken'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception(),
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
}
