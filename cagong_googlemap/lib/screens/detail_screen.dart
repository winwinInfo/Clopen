import 'package:flutter/material.dart';
import '../models/cafe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import 'login.dart';
import '../widgets/cafe_comment.dart';
import '../widgets/cafe_rating_section.dart'; 



class DetailScreen extends StatefulWidget {
  final Cafe cafe;

  const DetailScreen({super.key, required this.cafe});

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  int _selectedIndex = 0; // 0:info, 1:comment

  @override
  void initState() {
    super.initState();
  }



Widget _buildInfoContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            CafeRatingSection(
              cafeId: widget.cafe.id,
              editorComment: widget.cafe.message,
            ),

            const SizedBox(height: 20),

            // 예약 기능이 활성화된 경우
            if (widget.cafe.reservation.enabled) ...[
              Consumer<loginProvider.AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.userData != null) {
                    return Column(
                      children: [
                        Center(
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFdfd3c3),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              "예약하기",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0XFF6c5d53),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Center(
                      child: Column(
                        children: [
                          const Text(
                            "로그인 하시면 예약 기능을 사용할 수 있습니다.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "로그인 하러 가기",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    );
                  }
                },
              ),
            ] else ... [
              //예약 불가 카페일 때
              const Center(
                child: Text(
                  //"예약을 지원하지 않는 카페입니다.",
                  "", //걍 아무말도 안나오게
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                )
              )
            ],
          ],
        ),
      ),
    );
  }





  Widget _buildCommentsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            CommentsSection(cafeId: widget.cafe.id.toDouble()),
          ],
        ),
      ),
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.cafe.name,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildInfoContent(),
          _buildCommentsContent(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.brown,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: '정보',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.comment_outlined),
              activeIcon: Icon(Icons.comment),
              label: '댓글',
            ),
          ],
        ),
      ),
    );
  }





  @override
  void dispose() {
    super.dispose();
  }
}
