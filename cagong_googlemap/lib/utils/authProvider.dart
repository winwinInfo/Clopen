import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
    serverClientId: '447275815920-ijh2059s7qfvqu9aot4lsfhmvj72rnmo.apps.googleusercontent.com',
  );

  bool _isLoggedIn = false;
  String? _jwtToken;
  Map<String, dynamic>? _userData;

  bool get isLoggedIn => _isLoggedIn;
  String? get jwtToken => _jwtToken;
  Map<String, dynamic>? get userData => _userData;

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'isNewUser': false, 'idToken': null};
      }

      final googleAuth = await googleUser.authentication;

      print('idToken: ${googleAuth.idToken}');

      // idToken null 체크. null이면 엑셉션 던짐
      if (googleAuth.idToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다. serverClientId 설정을 확인해주세요.');
      }

      // Flask 서버에 idToken 보내기
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        // 신규 유저 체크
        if (data['is_new_user'] == true) {
          return {
            'success': true,
            'isNewUser': true,
            'idToken': googleAuth.idToken,
          };
        }

        // 기존 유저 로그인 처리
        _jwtToken = data['token'];
        _userData = data['user'];
        _isLoggedIn = true;
        notifyListeners();
        return {'success': true, 'isNewUser': false, 'idToken': null};
      } else {
        print('로그인 실패: ${response.body}');
        return {'success': false, 'isNewUser': false, 'idToken': null};
      }
    } catch (e) {
      print('Google 로그인 중 오류: $e');
      return {'success': false, 'isNewUser': false, 'idToken': null};
    }
  }

  Future<bool> registerWithNickname(String idToken, String nickname) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google-signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'nickname': nickname,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];
        _jwtToken = data['token'];
        _userData = data['user'];
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        print('회원가입 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('회원가입 중 오류: $e');
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _jwtToken = null;
    _userData = null;
    _googleSignIn.signOut(); // 구글 계정도 로그아웃
    notifyListeners();
  }
}
