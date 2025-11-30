import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ReservationService {



  /// 특정 시간대의 예약 가능 여부 확인
  ///
  /// [cafeId]: 카페 ID
  /// [date]: 날짜 문자열 (형식: YYYY-MM-DD)
  /// [time]: 시간 문자열 (형식: HH:MM)
  /// [duration]: 예약 시간 (시간 단위)
  /// Returns: Map<String, dynamic> (예약 가능 여부 및 상세 정보)
  /// Throws: Exception if the request fails
  static Future<Map<String, dynamic>> checkAvailability({
    required int cafeId,
    required String date,
    required String time,
    required int duration,
  }) async {
    try {
      // API 엔드포인트 URL 생성
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/reservations/availability?cafe_id=$cafeId&date=$date&time=$time&duration=$duration',
      );

      // GET 요청 전송
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          // API returned success: false
          throw Exception(
            responseData['error'] ?? '예약 가능 여부 확인에 실패했습니다',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('카페를 찾을 수 없습니다');
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        throw Exception(responseData['error'] ?? '잘못된 요청입니다');
      } else {
        // HTTP error (500, etc.)
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }





  /// 예약 생성
  ///
  /// [cafeId]: 카페 ID
  /// [userId]: 사용자 ID
  /// [date]: 날짜 문자열 (형식: YYYY-MM-DD)
  /// [time]: 시간 문자열 (형식: HH:MM)
  /// [duration]: 예약 시간 (시간 단위)
  /// [seatCount]: 예약 좌석 수 (기본값: 1)
  /// [paymentKey]: 토스페이먼츠 결제 키
  /// Returns: Map<String, dynamic> (예약 결과)
  /// Throws: Exception if the request fails
  static Future<Map<String, dynamic>> createReservation({
    required int cafeId,
    required int userId,
    required String date,
    required String time,
    required int duration,
    int seatCount = 1,
    String? paymentKey,
  }) async {
    try {
      // API 엔드포인트 URL 생성
      final uri = Uri.parse('${ApiConfig.baseUrl}/reservations/');

      // POST 요청 전송
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cafe_id': cafeId,
          'user_id': userId,
          'date': date,
          'time': time,
          'duration': duration,
          'seat_count': seatCount,
          'payment_key': paymentKey,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간 초과: 서버 응답이 없습니다');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
            responseData['message'] ?? '예약 생성에 실패했습니다',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('카페를 찾을 수 없습니다');
      } else if (response.statusCode == 400) {
        throw Exception(
          responseData['error'] ?? responseData['message'] ?? '잘못된 요청입니다',
        );
      } else {
        // HTTP error (500, etc.)
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
