import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return '올바른 이메일을 입력하세요';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 회원가입 함수
  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() == true) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);
        // 성공 시 처리 (예: 홈 화면으로 이동)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 성공!')),
        );
      } on FirebaseAuthException catch (e) {
        // FirebaseAuthException 처리
        String errorMessage = '회원가입 실패';
        if (e.code == 'weak-password') {
          errorMessage = '비밀번호가 너무 약합니다';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = '이 이메일은 이미 사용 중입니다';
        } else if (e.code == 'invalid-email') {
          errorMessage = '이메일 형식이 잘못되었습니다';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 중 오류가 발생했습니다')),
        );
      }
    }
  }
}
