import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';
import '../widgets/search_bar.dart' as CustomSearchBar;
import '../widgets/bottom_sheet.dart';
import 'dart:ui' as ui;

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Google 지도 컨트롤러를 위한 Completer
  Completer<GoogleMapController> _controller = Completer();
  // 초기 지도 중심 좌표 (서울시청)
  static const LatLng _center = const LatLng(37.5665, 126.9780);

  // 지도에 표시될 모든 마커를 저장하는 Set
  Set<Marker> _markers = {};
  // 로드된 카페 정보를 저장하는 리스트
  List<Cafe> _cafes = [];
  // 데이터 로딩 상태를 나타내는 플래그
  bool _isLoading = true;
  // 현재 위치를 나타내는 마커
  Marker? _currentLocationMarker;
  // 위치 추적을 위한 StreamSubscription
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadCafesAndCreateMarkers(); // 카페 데이터 로드 및 마커 생성
    _getCurrentLocation(); // 현재 위치 가져오기
    _startLocationTracking(); // 위치 추적 시작
  }

  @override
  void dispose() {
    // 위치 추적 구독 취소
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// 카페 데이터를 로드하고 마커를 생성하는 메서드
  Future<void> _loadCafesAndCreateMarkers() async {
    try {
      // JSON 파일에서 카페 데이터 로드
      String jsonString = await rootBundle.loadString('json/cafe_info.json');
      List<dynamic> jsonResponse = json.decode(jsonString);
      _cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

      // 각 카페에 대한 마커 생성
      for (final cafe in _cafes) {
        final markerIcon = await CustomMarkerGenerator.createCustomMarkerBitmap(
          cafe,
          imageScale: 0.3,
          titleFontSize: 14,
          subtitleFontSize: 12,
        );
        final marker = Marker(
          markerId: MarkerId('${cafe.latitude},${cafe.longitude}'),
          position: LatLng(cafe.latitude, cafe.longitude),
          icon: markerIcon,
          onTap: () => _showBottomSheet(cafe),
        );
        _markers.add(marker);
      }

      // 로딩 완료 상태 업데이트
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cafe data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 카페 정보를 보여주는 바텀 시트를 표시하는 메서드
  void _showBottomSheet(Cafe cafe) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheetContent(
          name: cafe.name,
          message: cafe.message,
          address: cafe.address,
          price: cafe.price,
          hoursWeekday: cafe.hoursWeekday.toString(),
          hoursWeekend: cafe.hoursWeekend.toString(),
          videoUrl: cafe.videoUrl,
          seatingInfo: cafe.seatingTypes
              .map((seating) => {
                    'type': seating.type,
                    'count': seating.count,
                    'power': seating.powerCount,
                  })
              .toList(),
        );
      },
    );
  }

  /// 현재 위치를 가져오고 마커를 업데이트하는 메서드
  Future<void> _getCurrentLocation() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 권한이 거부된 경우 처리
          return;
        }
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateCurrentLocationMarker(position);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  /// 실시간 위치 추적을 시작하는 메서드
  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateCurrentLocationMarker(position);
    });
  }

  /// 현재 위치 마커를 업데이트하는 메서드
  Future<void> _updateCurrentLocationMarker(Position position) async {
    final LatLng location = LatLng(position.latitude, position.longitude);
    final BitmapDescriptor markerIcon =
        await _createResizedMarkerImageFromAsset(
            'images/current_location_marker.png', 35);

    setState(() {
      // 기존 현재 위치 마커 제거
      if (_currentLocationMarker != null) {
        _markers.remove(_currentLocationMarker);
      }
      // 새로운 현재 위치 마커 생성 및 추가
      _currentLocationMarker = Marker(
        markerId: MarkerId('current_location'),
        position: location,
        icon: markerIcon,
        infoWindow: InfoWindow(title: '현재 위치'),
      );
      _markers.add(_currentLocationMarker!);
    });
  }

  /// 에셋 이미지를 로드하고 크기를 조정하여 BitmapDescriptor로 반환하는 메서드
  Future<BitmapDescriptor> _createResizedMarkerImageFromAsset(
      String assetName, int width) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final data2 = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data2!.buffer.asUint8List());
  }

  /// 현재 위치로 카메라를 이동시키는 메서드
  void _moveToCurrentLocation() async {
    if (_currentLocationMarker != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
          CameraUpdate.newLatLng(_currentLocationMarker!.position));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 로딩 중이면 로딩 인디케이터 표시, 아니면 구글 맵 표시
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 11.0,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                ),
          // 검색 바 위젯
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: CustomSearchBar.SearchBar(
              cafes: _cafes,
              onCafeSelected: _handleCafeSelected,
            ),
          ),
          // 현재 위치 버튼
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              child: Icon(Icons.my_location),
              onPressed: _moveToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }

  /// 구글 맵이 생성될 때 호출되는 콜백 메서드
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  /// 카페가 선택되었을 때 호출되는 메서드
  void _handleCafeSelected(Cafe selectedCafe) async {
    final GoogleMapController controller = await _controller.future;
    // 선택된 카페 위치로 카메라 이동
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
    ));
    // 카페 정보 바텀 시트 표시
    _showBottomSheet(selectedCafe);
  }
}
