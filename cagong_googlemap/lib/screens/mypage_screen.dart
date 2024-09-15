import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.user;
    final userData = authProvider.userData;

    if (user == null || userData == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이름: ${userData['name']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('이메일: ${user.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('별명: ${userData['nickname']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('성별: ${userData['gender']}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('생년월일: ${userData['birthDate'].toDate().toString().split(' ')[0]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('대학교: ${userData['university'] ?? '미입력'}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 24),
            ElevatedButton(
              child: Text('로그아웃'),
              onPressed: () async {
                await authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}