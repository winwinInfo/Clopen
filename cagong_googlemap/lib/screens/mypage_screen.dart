import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../models/rating.dart';
import '../services/rating_service.dart';

class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<Map<String, dynamic>> _ratedCafes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyRatings();
  }

  Future<void> _loadMyRatings() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
      final jwtToken = authProvider.jwtToken;

      if (jwtToken != null) {
        final ratings = await RatingService.getMyRatings(jwtToken: jwtToken);
        setState(() {
          _ratedCafes = ratings;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('평점 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMyRatings();  // 화면이 보일 때마다 내가 평점 매긴 카페 로드
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<loginProvider.AuthProvider>(context);
    final user = authProvider.userData;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '마이페이지',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              authProvider.logout();
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
            SizedBox(height: 24),

            // 인사말
            Center(
              child: Text(
                '반갑습니다, ${user['nickname'] ?? "사용자"}님',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            SizedBox(height: 24),

            // 내가 평점을 매긴 카페 제목
            Text(
              '내가 평점을 매긴 카페',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 12),

            // 평점 매긴 카페 목록
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _ratedCafes.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadMyRatings,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(
                              '아직 평점을 매긴 카페가 없습니다.\n아래로 당겨서 새로고침',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyRatings,
                      child: ListView.builder(
                        itemCount: _ratedCafes.length,
                        itemBuilder: (context, index) {
                        final ratedCafe = _ratedCafes[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              ratedCafe['cafe']['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  ratedCafe['cafe']['address'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Pretendard',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber[700],
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '내 평점: ${ratedCafe['rate']}점',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.brown[700],
                                        fontFamily: 'Pretendard',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // trailing: Icon(
                            //   Icons.chevron_right,
                            //   color: Colors.grey,
                            // ),
                          ),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
