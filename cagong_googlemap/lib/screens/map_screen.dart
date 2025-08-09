// // import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase removed
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';
import '../utils/cluster_marker.dart';
import '../utils/location_marker.dart';
import '../widgets/search_bar.dart' as custom_search_bar;
import '../widgets/bottom_sheet.dart';
import '../widgets/filter.dart';
import 'dart:ui' as ui;


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

  //현위치 마커 서비스 인스턴스
  final LocationMarkerService _locationService = LocationMarkerService();
  // 클러스터 마커 서비스 인스턴스
  final ClusterMarkerService _clusterService = ClusterMarkerService();


  @override
  void initState() {
    super.initState();

    // 위치 서비스 초기화 및 콜백 등록
    _initLocationService();
    // 클러스터 마커 초기화
    _initClusterService();
    // 카페 마커 load
    _loadCafesAndCreateMarkers();
  }

  // 클러스터 서비스 초기화
  void _initClusterService() {
    // 클러스터 탭 이벤트 처리
    _clusterService.onClusterTap = (cafes) {
      showClusterBottomSheet(context, cafes);
    };

    // 카페 탭 이벤트 처리
    _clusterService.onCafeTap = (cafe) {
      _handleCafeSelected(cafe);
    };
  }

  //현위치 서비스 초기화
  Future<void> _initLocationService() async {
    await _locationService.initializeCircleMarker();

    // 마커 업데이트 콜백 설정
    _locationService.onMarkerUpdate = (marker) {
      if (!mounted) return;
      setState(() {
        // 기존 현재 위치 마커 제거
        _markers.removeWhere((m) => m.markerId.value == 'current_location');
        // 새 마커 추가
        _markers.add(marker);
      });
    };

    // 위치 서비스 시작
    _locationService.getCurrentLocation();
    _locationService.startLocationTracking();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  // 현재 위치로 카메라 이동
  void _moveToCurrentLocation() async {
    final position = _locationService.getCurrentPosition();
    if (position != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(position));
    }
  }


  Future<void> _loadCafesAndCreateMarkers() async {
    try {
      String jsonString =
          await rootBundle.loadString('assets/json/cafe_info.json');
      List<dynamic> jsonResponse = json.decode(jsonString);
      _cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

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
    _updateMarkersForCafes(filteredCafes);
  }

  double _currentZoom = 11.0;
  
  void _updateMarkers(Set<Marker> markers) {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      _markers.addAll(markers);

      // LocationMarkerService에서 현재 위치 마커 가져오기
      if (_locationService.currentLocationMarker != null) {
        // 현재 위치 마커 추가
        _markers.add(_locationService.currentLocationMarker!);
      }

    });
  }
  
  // 카페 마커들을 업데이트하는 메서드
  Future<void> _updateMarkersForCafes(List<Cafe> cafes) async {
    Set<Marker> markers = await _clusterService.createMarkersWithClustering(cafes, _currentZoom);
    _updateMarkers(markers);
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
          _isBottomSheetOpen = false;
          _bottomSheetHeight = 0; // 바텀 시트가 닫히면 높이를 0으로 설정
        });
      }
    });

    // 바텀 시트가 열릴 때의 처리
    if (mounted) {
      setState(() {
        _isBottomSheetOpen = true;
        _bottomSheetHeight = 200; // 바텀 시트가 열릴 때의 높이
      });
    }
  }//showClusterBottomSheet


//화면 구성
  bool _isBottomSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBottomSheetOpen, //bottomSheet open -> false (BottomSheet open = can't pop)
      onPopInvoked: (didPop){
        // didPop이 false면 canPop이 false였기 때문에 시스템이 pop을 수행하지 않았음을 의미
        if(!didPop){
          // 바텀시트가 열려있으면, 바텀시트만 닫음
          if (_isBottomSheetOpen) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: _bottomSheetHeight),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  _updateMarkersForCafes(_filterManager.applyFilters(_cafes));
                  },
                  initialCameraPosition: const CameraPosition(
                  target: _center,
                  zoom: 11.0,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  onCameraMove: (CameraPosition position) {
                    _currentZoom = position.zoom;
                    },
                    onCameraIdle: () {
                      _updateMarkersForCafes(_filterManager.applyFilters(_cafes));
                    },
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
      ),
    );
  }


//when cafe selected
  void _handleCafeSelected(Cafe selectedCafe) async {
    final scaffoldContext = Scaffold.of(context);
    final GoogleMapController controller = await _controller.future;

    //move camera to selected cafe
    controller.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
      21.0,
    ));

    //checking mount (if widget is on tree)버
    if (!mounted) return;

    //Opening bottom sheet
    final bottomSheetController = scaffoldContext.showBottomSheet(
      (BuildContext context) => CafeBottomSheet(cafe: selectedCafe),
    );

    //when bottom sheet closed
    bottomSheetController.closed.then((_) {
      if (mounted) {
        setState(() {
          _isBottomSheetOpen = false;
          _bottomSheetHeight = 0;
        });
      }
    });

    //set bottom sheet's height
    if (mounted) {
      setState(() {
        _isBottomSheetOpen = true;
        _bottomSheetHeight = 200; //height
      });
    }
  }
}
