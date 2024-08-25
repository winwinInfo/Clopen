import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(37.5665, 126.9780); // 서울의 위도와 경도
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _addMarker(LatLng position) {
    final MarkerId markerId = MarkerId(position.toString());
    final Marker marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: '선택한 위치', snippet: '${position.latitude}, ${position.longitude}'),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('지도'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: Set<Marker>.of(markers.values),
        onTap: _addMarker,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.center_focus_strong),
        onPressed: () {
          _goToCenter();
        },
      ),
    );
  }

  Future<void> _goToCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _center, zoom: 11),
    ));
  }
}