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
import 'detail_screen.dart';




class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(37.5665, 126.9780);

  final Set<Marker> _markers = {};
  List<Cafe> _cafes = [];
  bool _isLoading = true;
  Marker? _currentLocationMarker;
  StreamSubscription<Position>? _positionStreamSubscription;

  Cafe? _selectedCafe;
  final GlobalKey<ExpandableBottomSheetState> _bottomSheetKey = GlobalKey();
  bool _isBottomSheetFullyExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadCafesAndCreateMarkers();
    _getCurrentLocation();
    _startLocationTracking();
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
          onTap: () => _handleCafeSelected(cafe),
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

  Future<void> _updateCurrentLocationMarker(Position position) async {
    final LatLng location = LatLng(position.latitude, position.longitude);
    final BitmapDescriptor markerIcon =
        await _createResizedMarkerImageFromAsset(
            'images/current_location_marker.png', 35);

    setState(() {
      if (_currentLocationMarker != null) {
        _markers.remove(_currentLocationMarker);
      }
      _currentLocationMarker = Marker(
        markerId: const MarkerId('current_location'),
        position: location,
        icon: markerIcon,
        infoWindow: const InfoWindow(title: '현재 위치'),
      );
      _markers.add(_currentLocationMarker!);
    });
  }

  Future<BitmapDescriptor> _createResizedMarkerImageFromAsset(
      String assetName, int width) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final data2 = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data2!.buffer.asUint8List());
  }

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
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: _center,
                    zoom: 11.0,
                  ),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  flex: 85, // 검색창의 너비를 80%로 설정
                  child: custom_search_bar.SearchBar(
                    cafes: _cafes,
                    onCafeSelected: _handleCafeSelected,
                  ),
                ),
                SizedBox(width: 5), // 간격 추가
                Expanded(
                  flex: 15, // 필터 버튼의 너비 설정
                  child: ElevatedButton(
                    onPressed: () {
                      showFilterDialog(context);
                    },
                    child: Icon(Icons.filter_list),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(0, 48), // 버튼의 최소 높이를 48로 설정
                      backgroundColor: Colors.blue, // 버튼 배경색 설정
                      foregroundColor: Colors.white, // 아이콘 색상 설정                      
                    ),
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
          ExpandableBottomSheet(
            key: _bottomSheetKey,
            background: Container(height: 0),
            expandableContent: _selectedCafe == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: _handleBottomSheetTap,
                    onVerticalDragUpdate: _handleBottomSheetDrag,
                    child: BottomSheetContent(
                      height: MediaQuery.of(context).size.height * 0.4,
                      name: _selectedCafe!.name,
                      message: _selectedCafe!.message,
                      address: _selectedCafe!.address,
                      price: _selectedCafe!.price,
                      hoursWeekday: _selectedCafe!.hoursWeekday.toString(),
                      hoursWeekend: _selectedCafe!.hoursWeekend.toString(),
                      videoUrl: _selectedCafe!.videoUrl,
                      seatingInfo: _selectedCafe!.seatingTypes
                          .map((seating) => {
                                'type': seating.type,
                                'count': seating.count,
                                'power': seating.powerCount,
                              })
                          .toList(),
                    ),
                  ),
            onIsExtendedCallback: () {
              setState(() {
                _isBottomSheetFullyExpanded = true;
              });
            },
            onIsContractedCallback: () {
              setState(() {
                _isBottomSheetFullyExpanded = false;
                _selectedCafe = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _handleCafeSelected(Cafe selectedCafe) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(
      LatLng(selectedCafe.latitude, selectedCafe.longitude),
    ));
    setState(() {
      _selectedCafe = selectedCafe;
    });

    //바텀 시트를 화면의 50%까지 확장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomSheetKey.currentState?.expand();
    });
  }

  void _handleBottomSheetTap() {
    if (_isBottomSheetFullyExpanded) {
      _navigateToDetailScreen();
    } else {
      _bottomSheetKey.currentState?.expand();
    }
  }

  void _handleBottomSheetDrag(DragUpdateDetails details) {
    if (details.primaryDelta! < -20 && _isBottomSheetFullyExpanded) {
      _navigateToDetailScreen();
    }
  }

  void _navigateToDetailScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailScreen(cafe: _selectedCafe!),
      ),
    );
  }
}
