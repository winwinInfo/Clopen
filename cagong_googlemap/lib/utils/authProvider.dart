import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _fetchUserData();
      notifyListeners();
    });
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

Future<UserCredential?> signInWithGoogle() async {
  try {
    UserCredential? userCredential;

    if (kIsWeb) {
      // 웹용 구글 로그인 로직
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      // 모바일용 구글 로그인 로직
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In was canceled by the user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    if (userCredential?.user == null) {
      print('Failed to sign in with Google: User is null');
      return null;
    }

    _user = userCredential!.user;

    // Firestore에 사용자 데이터가 있는지 확인
    DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
    
    if (!doc.exists) {
      // 사용자 데이터가 없으면 새로 생성
      await saveUserData(
        uid: _user!.uid,
        name: _user!.displayName ?? '',
        gender: '', // 구글 로그인으로는 성별 정보를 얻을 수 없음
        birthDate: DateTime.now(), // 기본값, 나중에 사용자가 수정할 수 있도록
        nickname: _user!.displayName ?? '',
        email: _user!.email ?? '',
        university: '', // 구글 로그인으로는 대학 정보를 얻을 수 없음
      );
    }

    // 사용자 데이터 가져오기
    await _fetchUserData();
    
    notifyListeners();
    return userCredential;

  } catch (e) {
    print('Error signing in with Google: $e');
    if (e is FirebaseAuthException) {
      print('FirebaseAuth error code: ${e.code}');
    } else if(e is PlatformException){
      print('Platform error code: ${e.code}');
    }
    return null;
  }
}

  Future<void> _fetchUserData() async {
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userData = doc.data() as Map<String, dynamic>?;
          notifyListeners();
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    } else {
      _userData = null;
    }
  }

  Future<UserCredential> createUser({required String email, required String password}) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      print('Error sending email verification: $e');
      rethrow;
    }
  }

  Future<bool> isEmailVerified(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user?.emailVerified ?? false;
    } catch (e) {
      print('Error checking email verification: $e');
      rethrow;
    }
  }

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String gender,
    required DateTime birthDate,
    required String nickname,
    required String email,
    String? university,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'gender': gender,
        'birthDate': birthDate,
        'nickname': nickname,
        'email': email,
        'university': university,
      });
      await _fetchUserData();  // 저장 후 최신 데이터를 가져옵니다.
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = userCredential.user;
      await _fetchUserData();
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _userData = null;
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // 추가: 사용자 데이터 업데이트 메서드
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user != null) {
      try {
        await _firestore.collection('users').doc(_user!.uid).update(data);
        await _fetchUserData();  // 업데이트 후 최신 데이터를 가져옵니다.
      } catch (e) {
        print('Error updating user data: $e');
        rethrow;
      }
    }
  }
}