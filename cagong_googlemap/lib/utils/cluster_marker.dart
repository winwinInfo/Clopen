import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

class ClusterMarkerService {
  // 싱글톤 패턴 구현
  static final ClusterMarkerService _instance = ClusterMarkerService._internal();
  factory ClusterMarkerService() => _instance;
  ClusterMarkerService._internal();

  // 클러스터 매니저
  late ClusterManager<Cafe> clusterManager;

  // 클러스터 마커 업데이트 콜백
  Function(Set<Marker>)? onMarkersUpdate;

  // 클러스터 매니저 초기화
  void initClusterManager(Function(Set<Marker>) updateMarkers) {
    clusterManager = ClusterManager<Cafe>(
      [],
      updateMarkers,
      markerBuilder: _markerBuilder,
    );
  }

  // 클러스터 마커 빌더
  Future<Marker> _markerBuilder(dynamic cluster) async {
    if (cluster.isMultiple) {
      // 클러스터 마커 처리
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        onTap: () {
          // 콜백을 통해 클러스터 탭 이벤트 전달
          if (onClusterTap != null) {
            onClusterTap!(cluster.items);
          }
        },
        icon: await _getClusterMarker(cluster.count),
      );
    } else {
      // 단일 마커 처리
      final cafe = cluster.items.first;

      // CustomMarkerGenerator 활용
      final markerIcon = await CustomMarkerGenerator.createCustomMarker(
        cafe,
        markerSize: 36,
        fontSize: 14,
        maxTextWidth: 400,
      );

      return Marker(
        markerId: MarkerId('${cafe.latitude},${cafe.longitude}'),
        position: LatLng(cafe.latitude, cafe.longitude),
        icon: markerIcon,
        onTap: () {
          // 콜백을 통해 카페 탭 이벤트 전달
          if (onCafeTap != null) {
            onCafeTap!(cafe);
          }
        },
        anchor: const Offset(0.5, 0.5),
      );
    }
  }

  // 클러스터 마커 아이콘 생성
  Future<BitmapDescriptor> _getClusterMarker(int clusterSize) async {
    // 디바이스 픽셀 비율 얻기
    final dpr = WidgetsBinding.instance.window.devicePixelRatio;

    // 기본 크기 설정
    final baseSize = 60 + (clusterSize * 0.3).clamp(0, 40);
    final adjustedSize = baseSize / dpr;
    final adjustedFontSize = (18 + (clusterSize * 0.1).clamp(0, 14)) / dpr;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    // 원 그리기
    canvas.drawCircle(
        Offset(adjustedSize / 2, adjustedSize / 2),
        adjustedSize / 2,
        paint
    );

    // 텍스트 그리기
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      text: TextSpan(
        text: clusterSize.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: adjustedFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
          adjustedSize / 2 - textPainter.width / 2,
          adjustedSize / 2 - textPainter.height / 2
      ),
    );

    final image = await recorder.endRecording().toImage(
        adjustedSize.toInt(),
        adjustedSize.toInt()
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }



  // 클러스터와 카페 탭 이벤트를 위한 콜백
  Function(List<Cafe>)? onClusterTap;
  Function(Cafe)? onCafeTap;

  // 아이템 설정
  void setItems(List<Cafe> cafes) {
    clusterManager.setItems(cafes);
  }

  // 맵 ID 설정
  void setMapId(int mapId) {
    clusterManager.setMapId(mapId);
  }

  // 지도 업데이트
  void updateMap() {
    clusterManager.updateMap();
  }

  // 카메라 이동 처리
  void onCameraMove(CameraPosition position) {
    clusterManager.onCameraMove(position);
  }
}