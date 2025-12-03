// // import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase removed
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/cafe.dart';
import '../services/cafe_service.dart';
import '../utils/cluster_manager_service.dart';
import '../utils/location_marker.dart';
import '../widgets/search_bar.dart' as custom_search_bar;
import '../widgets/bottom_sheet.dart';
import '../widgets/filter.dart';
import '../widgets/add_cafe_dialog.dart';







class MapScreen extends StatefulWidget {


  //화면 비활성화 시 호출될 콜백 
  final VoidCallback? onVisibilityChanged;


  const MapScreen({
    super.key,
    this.onVisibilityChanged, // 화면 비활성화 콜백 
    });

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
  PersistentBottomSheetController? _currentBottomSheetController;
  //현위치 마커 서비스 인스턴스
  final LocationMarkerService _locationService = LocationMarkerService();

  // 클러스터 마커 서비스 인스턴스 (late로 선언, build 후 초기화)
  late ClusterManagerService _clusterService;
  bool _screenWidthInitialized = false;
  bool _cafesLoaded = false;


  @override
  void initState() {
    super.initState();

    // 위치 서비스 초기화 및 콜백 등록
    _initLocationService();
    // 카페 마커 load
    // 클러스터링 하기 전에 일단 db에서 카페 데이터부터 로드해두고 시작.
    // 데이터는 _cafes에 저장 
    _loadCafesAndCreateMarkers();
  }

  @override
  //얘는 screen width 저장하는 것만 함
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_screenWidthInitialized) {
      final screenWidth = MediaQuery.of(context).size.width;

      if (screenWidth > 0) {
        // 화면 크기가 유효하면 서비스 초기화
        _clusterService = ClusterManagerService();
        _clusterService.initializeScreenSize(context);
        _screenWidthInitialized = true;

        print('ClusterService 초기화 완료 (화면 너비: $screenWidth)');

        // 카페 데이터도 로드되었으면 클러스터 설정
        _setupClusterIfReady();
      }
    }
  }




  // 두 조건이 모두 충족되었을 때만 클러스터 설정
  Future<void> _setupClusterIfReady() async {
    if (!_screenWidthInitialized || !_cafesLoaded) {
      print('클러스터 설정 대기 중 - 화면 너비: $_screenWidthInitialized, 카페 로드: $_cafesLoaded');
      return;
    }

    print('클러스터 설정 시작 (카페 ${_cafes.length}개)');

    // 카페 탭 이벤트
    _clusterService.onCafeTap = (cafe) {
      _handleCafeSelected(cafe);
    };

    // 클러스터 탭 이벤트 -> 바텀시트 열기
    _clusterService.onClusterTap = (cafes) {
      showClusterBottomSheet(context, cafes);
    };

    await _clusterService.setupWithCafes(_cafes, _updateMarkers);
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



  // 전체 카페 데이터 받아오기. ( 만드는 로직은 아님 )
  Future<void> _loadCafesAndCreateMarkers() async {
    try {
      _cafes = await CafeService.getAllCafes();
      _cafesLoaded = true;

      // 화면 너비도 초기화되었으면 클러스터 설정
      await _setupClusterIfReady();

      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cafes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }





  //필터 적용
  Future<void> _applyFilters() async {
    List<Cafe> filteredCafes = _filterManager.applyFilters(_cafes);
    await _clusterService.setItems(filteredCafes);
  }
  
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
  

  // 클러스터 바텀시트
  void showClusterBottomSheet(BuildContext context, List<Cafe> cafes) {
    // bottom sheet controller 저장
    _currentBottomSheetController = Scaffold.of(context).showBottomSheet(
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
                itemBuilder: (context, index) {
                  final cafe = cafes[index];
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
                separatorBuilder: (context, index) => const SizedBox(
                  width: 40,
                ),
              ))
            ],
          ),
        );
      },
    );

    // 바텀 시트가 닫힐 때의 처리
    _currentBottomSheetController!.closed.then((_) {
      if (mounted) {
        setState(() {
          _isBottomSheetOpen = false;
          _bottomSheetHeight = 0;
          _currentBottomSheetController = null;
        });
      }
    });

    // 바텀 시트가 열릴 때의 처리
    if (mounted) {
      setState(() {
        _isBottomSheetOpen = true;
        _bottomSheetHeight = 200;
      });
    }
  }


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
                    },
                    initialCameraPosition: const CameraPosition(
                      target: _center,
                      zoom: 11.0,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: _markers,
                    clusterManagers: {_clusterService.clusterManager},
                    //여기서 poi 탭 동작 추가
                    // onPoiClick: (PointOfInterest poi) {
                    //   print('POI tapped: ${poi.name}');
                    //   print('POI placeId: ${poi.placeId}');
                    //   print('POI position: ${poi.position}');
                    // },
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
            // 현위치 이동 버튼
            Positioned(
              bottom: 16 + _bottomSheetHeight,
              right: 16,
              child: FloatingActionButton(
                onPressed: _moveToCurrentLocation,
                backgroundColor: Colors.white,
                heroTag: 'location_button',
                child: const Icon(
                  Icons.my_location,
                  color: Colors.brown,
                ),
              ),
            ),
            // 카페 추가 버튼
            Positioned(
              bottom: 80 + _bottomSheetHeight,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showAddCafeDialog,
                backgroundColor: Colors.brown,
                heroTag: 'add_cafe_button',
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }






//when cafe selected
//지금은 카페마커 눌렀을 때랑, BottomSheet에서 카페 선택했을 때 
  void _handleCafeSelected(Cafe selectedCafe) async {
    final scaffoldContext = Scaffold.of(context);
    final GoogleMapController controller = await _controller.future;

    //move camera to selected cafe
    controller.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
      21.0,
    ));

    if (!mounted) return;

    // bottom sheet controller 저장
    _currentBottomSheetController = scaffoldContext.showBottomSheet(
      (BuildContext context) => CafeBottomSheet(cafe: selectedCafe),
    );

    //when bottom sheet closed
    _currentBottomSheetController!.closed.then((_) {
      if (mounted) {
        setState(() {
          _isBottomSheetOpen = false;
          _bottomSheetHeight = 0;
          _currentBottomSheetController = null; 
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

  // public 메서드로 변경 (외부에서 접근 가능)
  void closeBottomSheetIfOpen() {
    if (_currentBottomSheetController != null) {
      _currentBottomSheetController!.close();
      _currentBottomSheetController = null;

      if (mounted) {
        setState(() {
          _isBottomSheetOpen = false;
          _bottomSheetHeight = 0;
        });
      }
    }
  }


  // 현재 지도 중심 위치 가져오기
  Future<LatLng> _getMapCenter() async {
    final GoogleMapController controller = await _controller.future;
    final LatLngBounds bounds = await controller.getVisibleRegion();

    // 중심점 계산
    final double centerLat = (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final double centerLng = (bounds.northeast.longitude + bounds.southwest.longitude) / 2;

    return LatLng(centerLat, centerLng);
  }


  // 카페 추가 다이얼로그 표시
  void _showAddCafeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCafeDialog(
        getMapCenter: _getMapCenter,
        onCafeAdded: () {
          // 카페 추가 성공 시 지도 새로고침
          _loadCafesAndCreateMarkers();
        },
      ),
    );
  }

}