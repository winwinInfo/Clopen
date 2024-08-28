import 'package:cagong_googlemap/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/current_location_button.dart';
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
  Marker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    _loadCafesAndCreateMarkers();
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

  void _onLocationFound(Marker marker) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(marker.position));

    setState(() {
      if (_currentLocationMarker != null) {
        _markers.remove(_currentLocationMarker);
      }
      _currentLocationMarker = marker;
      _markers.add(_currentLocationMarker!);
    });
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
                  myLocationButtonEnabled: true,
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
            bottom: 16,
            right: 16,
            child: CurrentLocationButton(
              onLocationFound: _onLocationFound,
            ),
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
    // Bottom Sheet를 표시합니다.
    _showBottomSheet(selectedCafe);
  }
}
