import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';

class CafeRatingSection extends StatefulWidget {
  final int cafeId;

  const CafeRatingSection({super.key, required this.cafeId});

  @override
  State<CafeRatingSection> createState() => _CafeRatingSectionState();
}

class _CafeRatingSectionState extends State<CafeRatingSection> {
  RatingStats? _ratingStats;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRatingStats();
  }

  Future<void> _loadRatingStats() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
      final jwtToken = authProvider.jwtToken;

      final stats = await RatingService.getRatingStats(
        widget.cafeId,
        jwtToken: jwtToken,
      );

      setState(() {
        _ratingStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('평점 정보를 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // 카공지수 제출
  Future<void> _submitRating(int rate) async {
    if (_isSubmitting) return;

    final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
    final jwtToken = authProvider.jwtToken;

    if (jwtToken == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await RatingService.submitRating(
        cafeId: widget.cafeId,
        jwtToken: jwtToken,
        rate: rate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(_ratingStats?.myRating == null
                ? '카공지수가 등록되었습니다!'
                : '카공지수가 수정되었습니다!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
      }

      await _loadRatingStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('등록 실패: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 1),
            ),
          );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // 콘센트 평가 제출
  Future<void> _submitConsentRate(int consentRate) async {
    if (_isSubmitting) return;

    final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
    final jwtToken = authProvider.jwtToken;

    if (jwtToken == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await RatingService.submitRating(
        cafeId: widget.cafeId,
        jwtToken: jwtToken,
        consentRate: consentRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('콘센트 평가가 등록되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
      }

      await _loadRatingStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('등록 실패: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 1),
            ),
          );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // 좌석 평가 제출
  Future<void> _submitSeatRate(int seatRate) async {
    if (_isSubmitting) return;

    final authProvider = Provider.of<loginProvider.AuthProvider>(context, listen: false);
    final jwtToken = authProvider.jwtToken;

    if (jwtToken == null) {
      _showLoginPrompt();
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await RatingService.submitRating(
        cafeId: widget.cafeId,
        jwtToken: jwtToken,
        seatRate: seatRate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('좌석 평가가 등록되었습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
      }

      await _loadRatingStats();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('등록 실패: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 1),
            ),
          );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인이 필요합니다'),
        content: const Text('평점을 등록하려면 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text('로그인하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_ratingStats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFdfd3c3).withOpacity(0.6),
            const Color(0xFFc7b199).withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber[700], size: 24),
              const SizedBox(width: 8),
              const Text(
                '카공지수',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _ratingStats!.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/ 5.0',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.brown[600],
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),

          Text(
            '${_ratingStats!.totalCount}명 평가',
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown[700],
              fontFamily: 'Pretendard',
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            '카공하기에 얼마나 적합한가요?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final isSelected = _ratingStats!.myRating == ratingValue;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : () => _submitRating(ratingValue),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                          ? Colors.brown
                          : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                            ? Colors.brown
                            : Colors.brown.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                      ),
                      child: Center(
                        child: Text(
                          ratingValue.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.brown,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          if (_ratingStats!.myRating != null) ...[
            const SizedBox(height: 12),
            Text(
              '내 평점: ${_ratingStats!.myRating}점',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown[700],
                fontFamily: 'Pretendard',
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: Colors.brown, thickness: 0.5),
          const SizedBox(height: 16),

          // 콘센트 평가 섹션
          _buildSubRatingSection(
            icon: Icons.power,
            title: '콘센트',
            keyword: _ratingStats!.consentKeyword,
            myValue: _ratingStats!.myConsentRate,
            onSubmit: _submitConsentRate,
          ),

          const SizedBox(height: 16),

          // 좌석 평가 섹션
          _buildSubRatingSection(
            icon: Icons.chair,
            title: '좌석',
            keyword: _ratingStats!.seatKeyword,
            myValue: _ratingStats!.mySeatRate,
            onSubmit: _submitSeatRate,
          ),
        ],
      ),
    );
  }

  // 콘센트/좌석 평가 위젯 빌더
  Widget _buildSubRatingSection({
    required IconData icon,
    required String title,
    required String? keyword,
    required int? myValue,
    required Function(int) onSubmit,
  }) {
    const labels = ['적음', '보통', '많음'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.brown[600], size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
              ),
            ),
            if (keyword != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown[700],
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final value = index + 1;
            final isSelected = myValue == value;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: _isSubmitting ? null : () => onSubmit(value),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.brown
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.brown
                            : Colors.brown.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.brown,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
