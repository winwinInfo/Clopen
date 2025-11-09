import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoggedIn = false;
  String? _jwtToken;
  Map<String, dynamic>? _userData;

  bool get isLoggedIn => _isLoggedIn;
  String? get jwtToken => _jwtToken;
  Map<String, dynamic>? get userData => _userData;

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;

      print('idToken: ${googleAuth.idToken}');

      // Flask 서버에 idToken 보내기
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': googleAuth.idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];
        _userData = data['user'];
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        print('로그인 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Google 로그인 중 오류: $e');
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
