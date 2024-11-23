import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지',
        style: TextStyle(color: Colors.white)
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 사진 표시 (있는 경우)
            if (user.photoURL != null)
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user.photoURL!),
                ),
              ),
            SizedBox(height: 24),
            
            // 이름 표시
            if (user.displayName != null)
              Text(
                '이름: ${user.displayName}',
                style: TextStyle(fontSize: 18),
              ),
            SizedBox(height: 8),
            
            // 이메일 표시
            Text(
              '이메일: ${user.email ?? "미입력"}',
              style: TextStyle(fontSize: 18),
            ),
            
            SizedBox(height: 24),
            // ElevatedButton(
            //   child: Text('로그아웃'),
            //   onPressed: () async {
            //     await authProvider.signOut();
            //     Navigator.of(context).pushReplacementNamed('/login');
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}