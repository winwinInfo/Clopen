import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/cafe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider; 
import 'login.dart';
import '../widgets/cafe_comment.dart'; 


class DetailScreen extends StatefulWidget {
  final Cafe cafe;

  const DetailScreen({super.key, required this.cafe});

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  int _selectedIndex = 0; // 0:info, 1:comment
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.cafe.videoUrl.isNotEmpty) {
      final videoId =
          YoutubePlayerController.convertUrlToId(widget.cafe.videoUrl);
      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
            showControls: true,
            showVideoAnnotations: false,
          ),
        );
      }
    }
  }

  String _getUsageTimeText(double hours) {
    if (hours == -1) return '무제한';
    if (hours == 0) return '권장X';
    return '$hours 시간';
  }

  String _getBusinessHourText(String? hours) {
    if (hours == null || hours.isEmpty || hours == '-1') {
      return '휴무';
    }
    return hours;
  }

  Widget _buildBusinessHoursTable() {
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
            children: [
              '월',
              '화',
              '수',
              '목',
              '금',
              '토',
              '일',
            ]
                .map((day) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          day,
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
            children: [
              '월',
              '화',
              '수',
              '목',
              '금',
              '토',
              '일',
            ]
                .map((day) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _getBusinessHourText(
                            widget.cafe.dailyHours[day],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponImage() {
    String imageName = '${widget.cafe.name}쿠폰.png';

    return Center(
      child: Container(
        clipBehavior: Clip.hardEdge,
        width: 337.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
        ),
        child: Image.asset(
          'assets/images/coupons/$imageName',
        ),
      ),
    );
  }

  Widget _buildSeatingInfoTable() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0XFFc7b199).withOpacity(0.5),
      ),
      child: Table(
        border: TableBorder.all(
          color: Colors.white,
          width: 3,
        ),
        children: [
          const TableRow(
            children: [
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('좌석 유형',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('좌석 수',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)))),
              TableCell(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('콘센트 수',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
          ...widget.cafe.seatingTypes.map((seating) => TableRow(
                children: [
                  TableCell(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text(seating.type, textAlign: TextAlign.center))),
                  TableCell(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(seating.count.toString(),
                              textAlign: TextAlign.center))),
                  TableCell(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(seating.powerCount,
                              textAlign: TextAlign.center))),
                ],
              )),
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
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0XFFc7b199).withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                widget.cafe.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.cafe.address,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_food_beverage_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '아아가격ㆍ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.cafe.price,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.alarm_on_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '평일 권장 체류 시간ㆍ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _getUsageTimeText(widget.cafe.hoursWeekday),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.alarm_on_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '주말 권장 체류 시간ㆍ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _getUsageTimeText(widget.cafe.hoursWeekend),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("영업 시간", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildBusinessHoursTable(),
            const SizedBox(height: 20),
            const Text("좌석 정보", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildSeatingInfoTable(),
            const SizedBox(height: 20),
            if (_controller != null) ...[
              Center(
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFdfd3c3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    "카페 영상",
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
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                    maxHeight: 600,
                  ),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: YoutubePlayerControllerProvider(
                      controller: _controller!,
                      child: YoutubePlayer(
                        controller: _controller!,
                        aspectRatio: 9 / 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (widget.cafe.coWork == 1) ...[
              Consumer<loginProvider.AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.user != null) {
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
                              "쿠폰",
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
                        _buildCouponImage(),
                        const SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return Center(
                      child: Column(
                        children: [
                          const Text(
                            "로그인 하시면 쿠폰을 확인할 수 있습니다!",
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
            CommentsSection(cafeId: widget.cafe.id),
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
    if (!kIsWeb) {
      _controller?.close();
    } else {
      _controller?.pauseVideo();
      _controller = null;
    }
    super.dispose();
  }
}
