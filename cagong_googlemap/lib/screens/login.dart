import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../utils/app_router.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '로그인',
          style: TextStyle(color: Colors.white),
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
                  final result = await authProvider.signInWithGoogle();

                  if (!result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('구글 로그인에 실패했습니다')),
                    );
                    return;
                  }

                  // 신규 유저인 경우 닉네임 입력 Dialog 표시
                  if (result['isNewUser']) {
                    _showNicknameDialog(context, result['idToken'], authProvider);
                  } else {
                    // 기존 유저인 경우 마이페이지로 이동
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      (Router.of(context).routerDelegate as AppRouterDelegate)
                          .setNewRoutePath(RouteInformation(location: '/mypage'));
                    }
                  }
                },

                icon: Image.asset(
                  'assets/images/GoogleCon.png',
                  height: 24,
                  width: 24,
                ),
                label: Text(
                  'Google로 로그인',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNicknameDialog(BuildContext context, String idToken, loginProvider.AuthProvider authProvider) {
    final TextEditingController nicknameController = TextEditingController();

    Future<void> handleNicknameSubmit(BuildContext dialogContext) async {
      final nickname = nicknameController.text.trim();

      if (nickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임을 입력해주세요')),
        );
        return;
      }

      if (nickname.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임은 2자 이상이어야 합니다')),
        );
        return;
      }

      // 회원가입 처리
      final success = await authProvider.registerWithNickname(idToken, nickname);

      if (success) {
        Navigator.of(dialogContext).pop(); // Dialog 닫기

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입이 완료되었습니다!')),
        );

        // 마이페이지로 이동
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          (Router.of(context).routerDelegate as AppRouterDelegate)
              .setNewRoutePath(RouteInformation(location: '/mypage'));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입에 실패했습니다. 닉네임이 중복되었을 수 있습니다.')),
          //구체적으로 중복으로 실패한건지 확인해서 보여주는 로직 추가 예정
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false, // 배경 클릭으로 닫기 방지
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('닉네임 입력'),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('환영합니다! 사용하실 닉네임을 입력해주세요.'),
                SizedBox(height: 16),
                TextField(
                  controller: nicknameController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    border: OutlineInputBorder(),
                    hintText: '2-10자 이내',
                  ),
                  maxLength: 10,
                  onSubmitted: (_) => handleNicknameSubmit(dialogContext),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => handleNicknameSubmit(dialogContext),
              child: Text('완료'),
            ),
          ],
        );
      },
    );
  }
}
