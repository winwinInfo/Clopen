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


  String _getUsageTimeText(int? hours) {
    if (hours == null || hours == -1) return '무제한';
    if (hours == 0) return '권장X';
    return '$hours 시간';
  }

  Widget _buildBusinessHoursTable() {
    final operatingHours = widget.cafe.operatingHours;
    final days = [
      {'label': '월', 'hours': operatingHours.monday},
      {'label': '화', 'hours': operatingHours.tuesday},
      {'label': '수', 'hours': operatingHours.wednesday},
      {'label': '목', 'hours': operatingHours.thursday},
      {'label': '금', 'hours': operatingHours.friday},
      {'label': '토', 'hours': operatingHours.saturday},
      {'label': '일', 'hours': operatingHours.sunday},
    ];

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0XFFc7b199).withOpacity(0.5),
      ),
      child: Table(
        border: TableBorder.all(
          width: 3,
          color: Colors.white,
        ),
        children: [
          TableRow(
            children: days
                .map((day) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          day['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          TableRow(
            children: days
                .map((day) {
                  final hours = day['hours'] as DayHours?;
                  final text = hours != null
                      ? '${hours.begin ?? ''}-${hours.end ?? ''}'
                      : '휴무';
                  return TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }






Widget _buildInfoContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            CafeRatingSection(cafeId: widget.cafe.id),

            const SizedBox(height: 10),

            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0XFFc7b199).withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                widget.cafe.message ?? '카페 소개가 없습니다.',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoSection(),

            const SizedBox(height: 20),

            const Text("영업 시간", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildBusinessHoursTable(),
            const SizedBox(height: 20),
            
            // 유튜브 영상 로직 삭제
            
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




  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.place_rounded,
            label: '주소',
            value: widget.cafe.address,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.emoji_food_beverage_rounded,
            label: '아아 가격',
            value: widget.cafe.price ?? '가격 정보 없음',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.alarm_on_rounded,
            label: '평일 권장 시간',
            value: _getUsageTimeText(widget.cafe.hoursWeekday),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.alarm_on_rounded,
            label: '주말 권장 시간',
            value: _getUsageTimeText(widget.cafe.hoursWeekend),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.brown[600],
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
