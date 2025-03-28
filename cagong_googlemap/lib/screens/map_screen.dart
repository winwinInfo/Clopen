import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';
import '../widgets/search_bar.dart' as custom_search_bar;
import '../widgets/bottom_sheet.dart';
import '../widgets/filter.dart';
import 'dart:ui' as ui;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';

class LocationMarkerUtils {
  static BitmapDescriptor? _circleMarker;

  static Future<void> initializeCircleMarker() async {
    _circleMarker ??= await _createCircleMarker(Colors.red, 20);
  }

static Future<BitmapDescriptor> _createCircleMarker(
    Color color, double size) async {
  // 디바이스 픽셀 비율 가져오기
  final dpr = WidgetsBinding.instance.window.devicePixelRatio;
  
  // 크기를 픽셀 비율로 조정
  final adjustedSize = size / dpr;
  final borderWidth = 3 / dpr;  // 테두리 두께도 조정
  
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // 하얀색 테두리 Paint 객체
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // 컬러 원 Paint 객체
  final Paint circlePaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // 하얀색 테두리 원
  canvas.drawCircle(
    Offset(adjustedSize / 2, adjustedSize / 2), 
    adjustedSize / 2, 
    borderPaint
  );

  // 컬러 원 (테두리 안쪽)
  canvas.drawCircle(
    Offset(adjustedSize / 2, adjustedSize / 2), 
    adjustedSize / 2 - borderWidth, 
    circlePaint
  );

  final img = await pictureRecorder
      .endRecording()
      .toImage(adjustedSize.toInt(), adjustedSize.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}

  static BitmapDescriptor getCircleMarker() {
    if (_circleMarker == null) {
      throw Exception(
          "Circle marker not initialized. Call initializeCircleMarker() first.");
    }
    return _circleMarker!;
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(37.5665, 126.9780);

  final FilterManager _filterManager = FilterManager();
  final Set<Marker> _markers = {};
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  StreamSubscription<Position>? _positionStreamSubscription;
  double _bottomSheetHeight = 0;

  late ClusterManager<Cafe> _clusterManager;

  @override
  void initState() {
    super.initState();
    // 수정: ClusterManager 초기화
    _clusterManager = ClusterManager<Cafe>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
    _initializeLocationMarker();
    _loadCafesAndCreateMarkers();
    _getCurrentLocation();
    _startLocationTracking();
  }

  Future<void> _initializeLocationMarker() async {
    await LocationMarkerUtils.initializeCircleMarker();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCafesAndCreateMarkers() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/json/cafe_info.json');
      List<dynamic> jsonResponse = json.decode(jsonString);
      _cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

      // ClusterManager에 카페 추가
      _clusterManager.setItems(_cafes);
      _clusterManager.updateMap();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cafe data: $e');
    }
  }

  //필터 적용
  void _applyFilters() {
    List<Cafe> filteredCafes = _filterManager.applyFilters(_cafes);
    _clusterManager.setItems(filteredCafes);
    _clusterManager.updateMap();
  }

  // 추가: _updateMarkers 메서드
  void _updateMarkers(Set<Marker> markers) {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
      // 현재 위치 마커 유지
      if (_currentLocationMarker != null) {
        _markers.add(_currentLocationMarker!);
      }
    });
  }

  // 클러스터링 하면서 추가된 마커빌더
  Future<Marker> _markerBuilder(dynamic cluster) async {
    if (cluster.isMultiple) {
      // 클러스터 마커 처리
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        onTap: () {
          print('Cluster tapped with ${cluster.count} items');
          showClusterBottomSheet(context, cluster.items);
          // 클러스터 탭 처리 로직
        },
        icon: await _getClusterMarker(cluster.count),
      );
    } else {
      // 단일 마커 처리
      final cafe = cluster.items.first;
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
        onTap: () => _handleCafeSelected(cafe),
        anchor: const Offset(0.5, 0.5),
      );
    }
  }

  void showClusterBottomSheet(BuildContext context, List<Cafe> cafes) {
    // 바텀 시트 열기
    final bottomSheetController = Scaffold.of(context).showBottomSheet(
      (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                  child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: cafes.length,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                itemBuilder: (context, Index) {
                  final cafe = cafes[Index];
                  return GestureDetector(
                      onTap: () => _handleCafeSelected(cafe),
                      child: Row(
                        children: [
                          Text(
                            cafe.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ));
                },
                separatorBuilder: (context, Index) => const SizedBox(
                  width: 40,
                ),
              ))
            ],
          ),
        );
      },
    );

    // 바텀 시트가 닫힐 때의 처리
    bottomSheetController.closed.then((_) {
      if (mounted) {
        setState(() {
          _bottomSheetHeight = 0; // 바텀 시트가 닫히면 높이를 0으로 설정
        });
      }
    });

    // 바텀 시트가 열릴 때의 처리
    if (mounted) {
      setState(() {
        _bottomSheetHeight = 200; // 바텀 시트가 열릴 때의 높이
      });
    }
  }

Future<BitmapDescriptor> _getClusterMarker(int clusterSize) async {
  // MediaQuery를 사용하여 현재 디바이스의 픽셀 비율 얻기
  final dpr = WidgetsBinding.instance.window.devicePixelRatio;
  
  // 기본 크기를 픽셀 비율로 나누어 조정
  final baseSize = 60 + (clusterSize * 0.3).clamp(0, 40);
  final adjustedSize = baseSize / dpr;
  final adjustedFontSize = (18 + (clusterSize * 0.1).clamp(0, 14)) / dpr;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..color = Colors.brown
    ..style = PaintingStyle.fill;

  // 조정된 크기로 그리기
  canvas.drawCircle(
    Offset(adjustedSize / 2, adjustedSize / 2), 
    adjustedSize / 2, 
    paint
  );

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

//현위치 얻어오기
  void _getCurrentLocation() async {
    if (!mounted) return; // 위젯이 여전히 마운트된 상태인지 확인

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high, // LocationSettings 대신 desiredAccuracy 사용
      );
      _updateCurrentLocationMarker(position);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

//위치 추적
  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateCurrentLocationMarker(position);
    });
  }

//현위치 마커 업데이트
  void _updateCurrentLocationMarker(Position position) async {
    if (!mounted) return; // 위젯이 여전히 마운트된 상태인지 확인

    final LatLng location = LatLng(position.latitude, position.longitude);

    setState(() {
      if (_currentLocationMarker != null) {
        _markers.remove(_currentLocationMarker);
      }
      _currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: location,
        icon: LocationMarkerUtils.getCircleMarker(),
        infoWindow: const InfoWindow(title: '현재 위치'),
        zIndex: 100.0,
      );
      _markers.add(_currentLocationMarker!);
    });
  }

//현위치로 카메라 이동
  void _moveToCurrentLocation() async {
    if (_currentLocationMarker != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
          CameraUpdate.newLatLng(_currentLocationMarker!.position));
    }
  }

//화면 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _bottomSheetHeight),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                      _clusterManager.setMapId(controller.mapId);
                    },
                    initialCameraPosition: const CameraPosition(
                      target: _center,
                      zoom: 11.0,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: _markers,
                    onCameraMove: _clusterManager.onCameraMove,
                    onCameraIdle: _clusterManager.updateMap,
                  ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  flex: 85,
                  child: custom_search_bar.SearchBar(
                    cafes: _cafes,
                    onCafeSelected: _handleCafeSelected,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  flex: 15,
                  child: ElevatedButton(
                    onPressed: () => showFilterDialog(
                        context, _filterManager, _applyFilters),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16 + _bottomSheetHeight,
            right: 16,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white, // 배경색
              child: const Icon(
                Icons.my_location,
                color: Colors.brown, // 아이콘 색상
              ),
            ),
          ),
        ],
      ),
    );
  }

//카페 마커를 선택했을 때 실행되는 함수
  void _handleCafeSelected(Cafe selectedCafe) async {
    final scaffoldContext = Scaffold.of(context);
    final GoogleMapController controller = await _controller.future;

    //카메라를 선택된 카페 위치로 이동
    controller.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
      21.0,
    ));

    //mounted 체크 : 위젯이 트리에 있는지 확인
    if (!mounted) return;

    //바텀 시트 열기
    final bottomSheetController = scaffoldContext.showBottomSheet(
      (BuildContext context) => CafeBottomSheet(cafe: selectedCafe),
    );

    //바텀시트 닫힐 떄의 처리
    bottomSheetController.closed.then((_) {
      if (mounted) {
        setState(() {
          _bottomSheetHeight = 0;
        });
      }
    });

    //mounted 상태에서 바텀 시트의 높이 설정
    if (mounted) {
      setState(() {
        _bottomSheetHeight = 200; // 바텀 시트가 열릴 때의 높이
      });
    }
  }
}
