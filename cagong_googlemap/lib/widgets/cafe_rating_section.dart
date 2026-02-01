import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import '../utils/authProvider.dart' as loginProvider;
import '../screens/login.dart';

class CafeRatingSection extends StatefulWidget {
  final int cafeId;
  final String? editorComment;

  const CafeRatingSection({
    super.key,
    required this.cafeId,
    this.editorComment,
  });

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

    return Column(
      children: [
        // 1. 카공 적합도 섹션
        _buildSuitabilitySection(),

        const SizedBox(height: 12),

        // 2. 에디터 코멘트 섹션
        if (widget.editorComment != null && widget.editorComment!.isNotEmpty)
          _buildEditorCommentSection(),

        const SizedBox(height: 12),

        // 3. 평가하기 섹션
        _buildRatingInputSection(),
      ],
    );
  }

  // 1. 카공 적합도 섹션
  Widget _buildSuitabilitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.brown[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '카공 적합도',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                  fontFamily: 'Pretendard',
                ),
              ),
              const Spacer(),
              Text(
                '${_ratingStats!.totalCount}명 평가',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 카공지수
              Expanded(
                child: _buildStatItem(
                  label: '카공지수',
                  value: _ratingStats!.averageRating.toStringAsFixed(1),
                  icon: Icons.star,
                  iconColor: Colors.amber[600]!,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              // 콘센트
              Expanded(
                child: _buildStatItem(
                  label: '콘센트',
                  value: _ratingStats!.consentKeyword ?? '-',
                  icon: Icons.power,
                  iconColor: Colors.brown[600]!,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              // 좌석
              Expanded(
                child: _buildStatItem(
                  label: '좌석',
                  value: _ratingStats!.seatKeyword ?? '-',
                  icon: Icons.chair,
                  iconColor: Colors.brown[600]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  // 2. 에디터 코멘트 섹션
  Widget _buildEditorCommentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFFAF7F2),
        border: Border.all(color: Colors.brown.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.brown[600], size: 20),
              const SizedBox(width: 8),
              Text(
                '에디터 코멘트',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.editorComment!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown[800],
              fontFamily: 'Pretendard',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 3. 평가하기 섹션
  Widget _buildRatingInputSection() {
    return Container(
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, color: Colors.brown[700], size: 20),
              const SizedBox(width: 8),
              Text(
                '평가하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 카공지수 평가
          _buildRatingRow(
            label: '카공지수',
            options: ['1', '2', '3', '4', '5'],
            selectedValue: _ratingStats!.myRating,
            onSelect: _submitRating,
          ),

          const SizedBox(height: 12),

          // 콘센트 평가
          _buildRatingRow(
            label: '콘센트',
            options: ['적음', '보통', '많음'],
            selectedValue: _ratingStats!.myConsentRate,
            onSelect: _submitConsentRate,
          ),

          const SizedBox(height: 12),

          // 좌석 평가
          _buildRatingRow(
            label: '좌석',
            options: ['적음', '보통', '많음'],
            selectedValue: _ratingStats!.mySeatRate,
            onSelect: _submitSeatRate,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow({
    required String label,
    required List<String> options,
    required int? selectedValue,
    required Function(int) onSelect,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.brown[700],
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(options.length, (index) {
              final value = index + 1;
              final isSelected = selectedValue == value;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : () => onSelect(value),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.brown
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.brown
                              : Colors.brown.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          options[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.brown[700],
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
        ),
      ],
    );
  }
}
