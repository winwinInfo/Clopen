import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';

class ClusterMarkerService {
  final BuildContext context;

  // 최대 줌 레벨
  static const double maxZoomForClustering = 16.0;

  // 클러스터와 카페 탭 이벤트를 위한 콜백
  Function(List<Cafe>)? onClusterTap;
  Function(Cafe)? onCafeTap;

  // 일반 클래스 생성자 (BuildContext 받음)
  ClusterMarkerService(this.context);

  // MediaQuery 기반 반응형 마커 크기 계산
  Map<String, double> _calculateResponsiveMarkerSize(double currentZoom) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dpi = MediaQuery.of(context).devicePixelRatio;

    double baseMarkerSize = screenWidth * 0.4;

    // 줌 레벨에 따른 스케일 조정
    double zoomFactor = 1.0;
    if (currentZoom >= 16) {
      zoomFactor = 1.2;
    } else if (currentZoom >= 14) {
      zoomFactor = 1.0;
    } else {
      zoomFactor = 0.8;
    }

    double markerSize = (baseMarkerSize * zoomFactor).clamp(75.0, 200.0);
    double fontSize = (markerSize * 0.3).clamp(24.0, 32.0);
    double maxTextWidth = screenWidth * 0.6;

    return {
      'markerSize': markerSize,
      'fontSize': fontSize,
      'maxTextWidth': maxTextWidth,
    };
  }

  // 마커 생성
  Future<Set<Marker>> createMarkersWithClustering(List<Cafe> cafes, double currentZoom) async {
    Set<Marker> markers = {};

    // 반응형 크기 계산
    final sizes = _calculateResponsiveMarkerSize(currentZoom);
    final markerSize = sizes['markerSize']!;
    final fontSize = sizes['fontSize']!;
    final maxTextWidth = sizes['maxTextWidth']!;

    if (currentZoom >= maxZoomForClustering) {
      // 최대 줌에서는 모든 카페 마커 표시
      for (Cafe cafe in cafes) {
        final markerIcon = await CustomMarkerGenerator.createCustomMarker(
          cafe,
          markerSize: markerSize,
          fontSize: fontSize,
          maxTextWidth: maxTextWidth,
        );

        markers.add(Marker(
          markerId: MarkerId(cafe.id.toString()),
          position: LatLng(cafe.latitude, cafe.longitude),
          icon: markerIcon,
          onTap: () {
            if (onCafeTap != null) {
              onCafeTap!(cafe);
            }
          },
        ));
      }
    } else {
      // 낮은 줌 레벨에서는 클러스터링 수행
      List<ClusteredCafe> clusters = performClustering(cafes, currentZoom);
      
      for (ClusteredCafe cluster in clusters) {
        if (cluster.isCluster) {
          // 클러스터 마커 생성
          final clusterIcon = await _getClusterMarker(cluster.cafes.length);
          markers.add(Marker(
            markerId: MarkerId('cluster_${cluster.id}'),
            position: cluster.center,
            icon: clusterIcon,
            onTap: () {
              if (onClusterTap != null) {
                onClusterTap!(cluster.cafes);
              }
            },
          ));
        } else {
          // 단일 카페 마커
          final cafe = cluster.cafes.first;
          final markerIcon = await CustomMarkerGenerator.createCustomMarker(
            cafe,
            markerSize: markerSize,
            fontSize: fontSize,
            maxTextWidth: maxTextWidth,
          );

          markers.add(Marker(
            markerId: MarkerId(cafe.id.toString()),
            position: LatLng(cafe.latitude, cafe.longitude),
            icon: markerIcon,
            onTap: () {
              if (onCafeTap != null) {
                onCafeTap!(cafe);
              }
            },
          ));
        }
      }
    }

    return markers;
  }

  // 클러스터링 수행
  List<ClusteredCafe> performClustering(List<Cafe> cafes, double zoom) {
    List<ClusteredCafe> clusters = [];
    List<Cafe> remaining = List.from(cafes);
    
    // 줌 레벨에 따른 클러스터 거리 조정
    double clusterDistance = _getClusteringDistance(zoom);
    
    while (remaining.isNotEmpty) {
      Cafe current = remaining.removeAt(0);
      List<Cafe> nearCafes = [current];
      
      // 가까운 카페들 찾기
      remaining.removeWhere((cafe) {
        double distance = _calculateDistance(
          current.latitude, current.longitude,
          cafe.latitude, cafe.longitude
        );
        if (distance <= clusterDistance) {
          nearCafes.add(cafe);
          return true;
        }
        return false;
      });
      
      clusters.add(ClusteredCafe(
        id: '${DateTime.now().millisecondsSinceEpoch}_${clusters.length}',
        cafes: nearCafes,
        isCluster: nearCafes.length > 1,
      ));
    }
    
    return clusters;
  }

  // 줌 레벨에 따른 클러스터 거리 계산
  double _getClusteringDistance(double zoom) {
    // 줌이 낮을수록 더 넓은 범위에서 클러스터링
    if (zoom <= 10) return 0.05;
    if (zoom <= 12) return 0.02;
    if (zoom <= 14) return 0.01;
    return 0.005;
  }

  // 두 지점 간 거리 계산 (단순 직선 거리)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    return (dLat * dLat + dLon * dLon).abs();
  }

  // 클러스터 마커 아이콘 생성 (반응형)
  Future<BitmapDescriptor> _getClusterMarker(int clusterSize) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final dpi = MediaQuery.of(context).devicePixelRatio;

    // 화면 크기 기반 계산
    final baseSize = (screenWidth * 1.5 + (clusterSize * 0.3).clamp(0, 40)).clamp(75.0, 9600.0);
    final adjustedSize = baseSize / dpi;
    final adjustedFontSize = ((baseSize * 0.3) + (clusterSize * 0.1).clamp(0, 24)) / dpi;

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
}





// 클러스터링된 카페 데이터 모델
class ClusteredCafe {
  final String id;
  final List<Cafe> cafes;
  final bool isCluster;
  
  ClusteredCafe({
    required this.id,
    required this.cafes,
    required this.isCluster,
  });
  
  LatLng get center {
    double lat = 0;
    double lng = 0;
    
    for (Cafe cafe in cafes) {
      lat += cafe.latitude;
      lng += cafe.longitude;
    }
    
    return LatLng(lat / cafes.length, lng / cafes.length);
  }
}
