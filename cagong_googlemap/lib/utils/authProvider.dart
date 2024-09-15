import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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