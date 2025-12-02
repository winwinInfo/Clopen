import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';

/// 네이티브 google_maps_flutter 클러스터링 전담 서비스
class ClusterManagerService {
  // 화면 크기 캐싱 (앱 실행 중 변하지 않음)
  double? _screenWidth;

  // 네이티브 ClusterManager
  late final ClusterManager _nativeClusterManager;

  // 카페 데이터와 마커 매핑
  final Map<MarkerId, Cafe> _cafeMarkerMap = {};

  // 현재 마커 세트
  Set<Marker> _currentMarkers = {};

  // 콜백
  Function(Cafe)? onCafeTap;
  Function(List<Cafe>)? onClusterTap;
  Function(Set<Marker>)? _updateMarkersCallback;

  ClusterManagerService() {
    _nativeClusterManager = ClusterManager(
      clusterManagerId: const ClusterManagerId('cafe_cluster'),
      onClusterTap: _handleClusterTapInternal,
    );
  }

  /// 화면 크기 초기화 (0이 아닌 값일 때만 저장)
  void initializeScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 0) {
      _screenWidth = width;
      print('화면 크기 캐싱 완료: $_screenWidth');
    } else {
      print('경고: 화면 크기가 0입니다. 캐싱하지 않습니다.');
    }
  }

  /// 클러스터 탭 내부 핸들러
  void _handleClusterTapInternal(Cluster cluster) {
    // 클러스터에 속한 마커들의 카페 정보 추출
    final List<Cafe> cafesInCluster = [];

    for (final markerId in cluster.markerIds) {
      final cafe = _cafeMarkerMap[markerId];
      if (cafe != null) {
        cafesInCluster.add(cafe);
      }
    }

    // 외부 콜백 호출
    if (onClusterTap != null && cafesInCluster.isNotEmpty) {
      onClusterTap!(cafesInCluster);
    }
  }

  /// 네이티브 ClusterManager getter
  ClusterManager get clusterManager => _nativeClusterManager;

  /// 초기화 - 카페 데이터를 마커로 변환
  Future<void> initClusterManager(
    List<Cafe> cafes,
    Function(Set<Marker>) updateMarkers,
  ) async {
    _updateMarkersCallback = updateMarkers;
    await setItems(cafes);
  }

  /// 카페 리스트를 마커로 변환하여 설정
  Future<void> setItems(List<Cafe> cafes) async {
    _cafeMarkerMap.clear();

    print( "set item 호출됨 ! 총 ${cafes.length}개 카페" );
    final Set<Marker> newMarkers = {};

    // 화면 크기가 설정되지 않았으면 에러
    if (_screenWidth == null || _screenWidth! <= 0) {

      print('에러: 화면 크기가 초기화되지 않았습니다. initializeScreenSize를 먼저 호출하세요.');
      return;
    }

    // 반응형 마커 크기 계산
    final sizes = _calculateResponsiveMarkerSize(18.0);

    // 디버깅: 처음 3개 카페의 마커 좌표 확인
    print('===== 마커 생성 좌표 확인 =====');
    int debugCount = 0;

    for (final cafe in cafes) {
      final markerId = MarkerId('cafe_${cafe.id}');
      _cafeMarkerMap[markerId] = cafe;


      //////디버깅
      if (debugCount < 50) {
        print('마커 ${debugCount + 1}: ${cafe.name}');
        print('  - position: ${cafe.location}');
        print('  - latitude: ${cafe.latitude}, longitude: ${cafe.longitude}');
        debugCount++;
      }
      //////디버깅

      // 개별 카페 커스텀 마커 아이콘 생성
      final icon = await CustomMarkerGenerator.createCustomMarker(
        cafe,
        markerSize: sizes['markerSize']!,
        fontSize: sizes['fontSize']!,
        maxTextWidth: sizes['maxTextWidth']!,
      );

      final marker = Marker(
        markerId: markerId,
        position: cafe.location,
        icon: icon,
        clusterManagerId: _nativeClusterManager.clusterManagerId,
        onTap: () {
          if (onCafeTap != null) {
            onCafeTap!(cafe);
          }
        },
      );

      newMarkers.add(marker);
    }

    _currentMarkers = newMarkers;

    // 마커 업데이트 콜백 호출
    if (_updateMarkersCallback != null) {
      _updateMarkersCallback!(newMarkers);
    }
  }


  /// 현재 마커 세트 반환
  Set<Marker> get currentMarkers => _currentMarkers;

  /// 반응형 마커 크기 계산
  Map<String, double> _calculateResponsiveMarkerSize(double offset) {
    // 캐싱된 화면 크기 사용 (MediaQuery 호출 안함)
    double baseMarkerSize = _screenWidth! * 0.15;

    //줌 레벨에 따른 크기 조정 로직이었으나 deprecated 
    double offsetFactor = 1.0;
    if (offset >= 16) {
      offsetFactor = 1.2;
    } else if (offset >= 14) {
      offsetFactor = 1.0;
    } else {
      offsetFactor = 0.8;
    }

    double markerSize = (baseMarkerSize * offsetFactor).clamp(36.0, 72.0);
    double fontSize = (markerSize * 0.5).clamp(24.0, 48.0);
    double maxTextWidth = _screenWidth! * 1000; // 무제한
    print( "   @@@@ 생성된 마커 사이즈 정보 :  ${markerSize}, ${fontSize}, ${maxTextWidth}   @@@@   ");

    return {
      'markerSize': markerSize,
      'fontSize': fontSize,
      'maxTextWidth': maxTextWidth,
    };
  } 
}