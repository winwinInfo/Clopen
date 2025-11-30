import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/cafe_service.dart';

class AddCafeDialog extends StatefulWidget {
  final Future<LatLng> Function() getMapCenter;
  final VoidCallback onCafeAdded;

  const AddCafeDialog({
    super.key,
    required this.getMapCenter,
    required this.onCafeAdded,
  });

  @override
  State<AddCafeDialog> createState() => _AddCafeDialogState();
}

class _AddCafeDialogState extends State<AddCafeDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _useMapCenter = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCafes() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _showSnackBar('검색어를 입력해주세요.');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      double? latitude;
      double? longitude;

      // 현재 지도 중심 검색 체크 시
      if (_useMapCenter) {
        final center = await widget.getMapCenter();
        latitude = center.latitude;
        longitude = center.longitude;
      }

      // Places API 검색
      final results = await CafeService.searchCafesFromPlaces(
        query: query,
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isEmpty) {
        _showSnackBar('검색 결과가 없습니다.');
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      _showSnackBar('검색 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _addCafe(Map<String, dynamic> cafe) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카페 추가'),
        content: Text('"${cafe['name']}"을(를) 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 로딩 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 카페 추가 API 호출
      final result = await CafeService.addCafeFromPlaces(
        name: cafe['name'],
        address: cafe['address'] ?? '',
        latitude: cafe['latitude'],
        longitude: cafe['longitude'],
      );

      // 로딩 다이얼로그 닫기
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // 성공
        _showSnackBar(result['message'] ?? '카페가 추가되었습니다.');

        // AddCafeDialog 닫기
        Navigator.of(context).pop();

        // 지도 새로고침 콜백 호출
        widget.onCafeAdded();
      } else {
        // 실패 처리
        final isDuplicate = result['isDuplicate'] == true;

        if (isDuplicate) {
          // 중복 카페인 경우
          _showSnackBar('이미 추가된 카페입니다.');
        } else {
          // 기타 오류 (필수값 누락 등)
          final errorMessage = result['error'];
          if (errorMessage == 'cafe name is required') {
            _showSnackBar('카페 이름이 필요합니다.');
          } else if (errorMessage == 'location is required') {
            _showSnackBar('위치 정보가 필요합니다.');
          } else {
            _showSnackBar(errorMessage ?? '카페 추가에 실패했습니다.');
          }
        }
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (!mounted) return;
      Navigator.of(context).pop();

      _showSnackBar('카페 추가 중 오류가 발생했습니다: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            const Text(
              '카페 추가',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 검색어 입력
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '검색어',
                hintText: '예: 스타벅스 강남',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchCafes(),
            ),
            const SizedBox(height: 10),

            // 현재 지도 중심 검색 체크박스
            CheckboxListTile(
              title: const Text('현재 지도 중심 검색'),
              value: _useMapCenter,
              onChanged: (value) {
                setState(() {
                  _useMapCenter = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),

            // 검색 버튼
            ElevatedButton(
              onPressed: _isSearching ? null : _searchCafes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('검색'),
            ),
            const SizedBox(height: 20),

            // 검색 결과
            if (_searchResults.isNotEmpty) ...[
              const Text(
                '검색 결과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final cafe = _searchResults[index];
                    return ListTile(
                      title: Text(
                        cafe['name'] ?? '이름 없음',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        cafe['address'] ?? '주소 정보 없음',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _addCafe(cafe),
                      trailing: const Icon(Icons.add_circle_outline),
                    );
                  },
                ),
              ),
            ] else if (!_isSearching) ...[
              const Expanded(
                child: Center(
                  child: Text(
                    '검색어를 입력하고\n검색 버튼을 눌러주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
