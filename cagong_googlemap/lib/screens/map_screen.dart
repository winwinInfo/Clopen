import 'package:flutter/gestures.dart';
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
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';


class LocationMarkerUtils {
  static BitmapDescriptor? _circleMarker;

  static Future<void> initializeCircleMarker() async {
    if (_circleMarker == null) {
      _circleMarker = await _createCircleMarker(Colors.red, 20);
    }
  }

static Future<BitmapDescriptor> _createCircleMarker(Color color, double size) async { //원 모양 마커 만들기
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // 하얀색 테두리 Paint 객체
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // 빨간색 원 Paint 객체
  final Paint circlePaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // 하얀색 테두리 원 (테두리 역할, 빨간 원보다 크기 큼)
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, borderPaint);

  // 빨간색 원 (하얀색 테두리 안에 들어가도록 약간 작게)
  canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 3, circlePaint);

  final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}


  static BitmapDescriptor getCircleMarker() {
    if (_circleMarker == null) {
      throw Exception("Circle marker not initialized. Call initializeCircleMarker() first.");
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

  List<Cafe> _filteredCafes = [];
  final Set<Marker> _markers = {};
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  StreamSubscription<Position>? _positionStreamSubscription;

  Cafe? _selectedCafe;
  final GlobalKey<ExpandableBottomSheetState> _bottomSheetKey = GlobalKey();
  double _bottomSheetHeight = 0;

  late ClusterManager<Cafe> _clusterManager;

  @override
  void initState() {
    super.initState();
    // 수정: ClusterManager 초기화
    _clusterManager = ClusterManager<Cafe>(
      [],
      _updateMarkers,
      markerBuilder : _markerBuilder,
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
      String jsonString = await rootBundle.loadString('json/cafe_info.json');
      List<dynamic> jsonResponse = json.decode(jsonString);
      _cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

      // ClusterManager에 카페 추가
      _clusterManager.setItems(_cafes);
      _clusterManager.updateMap();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cafe data: $e');
    }
  }

  // 추가: _updateMarkers 메서드
  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
      // 현재 위치 마커 유지
      if (_currentLocationMarker != null) {
        _markers.add(_currentLocationMarker!);
      }
    });
  }
    //   for (final cafe in _cafes) {
    //     final markerIcon = await CustomMarkerGenerator.createCustomMarkerBitmap(
    //       cafe,
    //       markerSize: 32, // 마커 크기 조절
    //       fontSize: 12,    // 글씨 크기 조절
    //       maxTextWidth: 200, // 최대 텍스트 너비 설정
    //     );
    //     final marker = Marker(
    //       markerId: MarkerId('${cafe.latitude},${cafe.longitude}'),
    //       position: LatLng(cafe.latitude, cafe.longitude),
    //       icon: markerIcon,
    //       anchor: Offset(0.5, 0.5),  // 여기서 Offset을 사용합니다.
    //       onTap: () => _handleCafeSelected(cafe),
    //     );
    //     _markers.add(marker);
    //   }

    //   setState(() {
    //     _isLoading = false;
    //   });
    // } catch (e) {
    //   print('Error loading cafe data: $e');
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
  

  // 추가: _markerBuilder 메서드
  Future<Marker>_markerBuilder(dynamic cluster) async {
    if(cluster is Cluster<Cafe>){
      return Marker(
            markerId: MarkerId(cluster.getId()),
            position: cluster.location,
            onTap: () {
              if (cluster.isMultiple) {
                // 클러스터를 탭했을 때의 동작
              } else {
                // 단일 카페 마커를 탭했을 때의 동작
                _handleCafeSelected(cluster.items.first);
              }
            },
            icon: await _getMarkerBitmap(cluster.isMultiple ? 125 : 75,
                text: cluster.isMultiple ? cluster.count.toString() : null),
          );
    }
    else{
      return Marker(
        markerId: MarkerId('default'),
        position: const LatLng(0, 0),
      );
    }
  }

  // 클러스터링 마커 그리기
  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String? text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()..color = Colors.blue;
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(fontSize: size / 3, color: Colors.white, fontWeight: FontWeight.normal),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final image = await pictureRecorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }




//현위치 얻어오기
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
Future<void> _updateCurrentLocationMarker(Position position) async {
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
      zIndex:100.0,
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
                    onPressed: () => showFilterDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }


//카페 마커를 선택했을 때 실행되는 함수
  void _handleCafeSelected(Cafe selectedCafe) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
    ));
    setState(() {
      _selectedCafe = selectedCafe;
    });

    final bottomSheetController = Scaffold.of(context).showBottomSheet(
      (BuildContext context) => CafeBottomSheet(cafe: selectedCafe),
    );
    bottomSheetController.closed.then((_) {
      setState(() {
        _bottomSheetHeight = 0;
      });
    });

    setState(() {
      _bottomSheetHeight = 150; // 바텀 시트가 열릴 때의 높이
    });
  }
}




