import 'package:cagong_googlemap/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cafe.dart';
import '../utils/custom_marker_generator.dart';
import '../widgets/search_bar.dart' as CustomSearchBar;

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(37.5665, 126.9780);

  Set<Marker> _markers = {};
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  bool _myLocationEnabled = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  // 검색을 위한 TextEditingController 추가
  //TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCafesAndCreateMarkers();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
      }
    }
  }

  Future<void> _loadCafesAndCreateMarkers() async {
    try {
      String jsonString = await rootBundle.loadString('json/cafe_info.json');
      List<dynamic> jsonResponse = json.decode(jsonString);
      _cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 제거함
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 11.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                ),
          // 상단에 SearchBar 추가
          Positioned(
            top: MediaQuery.of(context).padding.top + 10, // 상태 바 높이 + 추가 패딩
            left: 10,
            right: 10,
            child: CustomSearchBar.SearchBar(
              //controller: _searchController,
              cafes: _cafes,
              onCafeSelected: _handleCafeSelected,
            ),
          ),
          Positioned(
            //현위치 버튼
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              child: Icon(Icons.my_location),
              onPressed: _goToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> _toggleLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 권한 설정을 확인해주세요.')),
      );
      return;
    }

    setState(() {
      _myLocationEnabled = !_myLocationEnabled;
    });

    if (_myLocationEnabled) {
      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    setState(() {
      _myLocationEnabled = true;
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateCameraPosition(position);
    });

    _goToCurrentLocation();
  }

  void _stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _updateCameraPosition(Position position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(position.latitude, position.longitude),
    ));
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateCameraPosition(position);
    } catch (e) {
      print('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져오는데 실패했습니다.')),
      );
    }
  }

  void _handleCafeSelected(Cafe selectedCafe) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
    ));
    // Bottom Sheet를 표시합니다.
    _showBottomSheet(selectedCafe);
  }
}
