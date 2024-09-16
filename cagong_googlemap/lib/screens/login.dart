import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/authProvider.dart' as loginProvider;
import 'register_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/app_router.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: Text('로그인'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
                  final userCredential = await authProvider.signInWithGoogle();
                  if (userCredential != null) {
                    // 구글 로그인 성공
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                     (Router.of(context).routerDelegate as AppRouterDelegate).setNewRoutePath(RouteInformation(location: '/mypage'));
                    }
                  } else {
                    // 구글 로그인 실패
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구글 로그인 실패')),
                    );
                  }
                },
                child: Text('Google로 로그인'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SignUpScreen(),
                    ),
                  );
                },
                child: Text('계정이 없으신가요? 회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
        await authProvider.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          (Router.of(context).routerDelegate as AppRouterDelegate).setNewRoutePath(RouteInformation(location: '/mypage'));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    }
  }
}