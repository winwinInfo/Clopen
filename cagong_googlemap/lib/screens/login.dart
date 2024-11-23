import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../utils/app_router.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인',
        style: TextStyle(
        color: Colors.white, // 텍스트 색상을 하얗게 변경
          ),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '환영합니다!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
                  final userCredential = await authProvider.signInWithGoogle();
                  if (userCredential != null) {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      (Router.of(context).routerDelegate as AppRouterDelegate)
                          .setNewRoutePath(RouteInformation(location: '/mypage'));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구글 로그인에 실패했습니다')),
                    );
                  }
                },
                icon: Image.asset(
                  'assets/images/GoogleCon.png',
                  height: 24,  // 이미지 크기 조절
                  width: 24,   // 이미지 크기 조절
                ),
                label: Text(
                  'Google로 로그인',
                  style: TextStyle(color: Colors.black), // 텍스트 색상 설정
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // 버튼 배경색을 하얗게 설정
                  foregroundColor: Colors.black, // 텍스트 색상 (강조 색상)
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}