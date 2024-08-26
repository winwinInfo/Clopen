import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:convert'; // JSON 파싱을 위한 패키지
import 'package:flutter/services.dart'
    show rootBundle; // assets에서 파일을 불러오기 위한 패키지
import '../widgets/map_markers.dart'; // 마커 관련 함수 임포트
import '../models/cafe.dart'; // Cafe 모델 임포트

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(37.5665, 126.9780);

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // JSON 파일에서 데이터를 로드하고 마커를 생성하는 함수
  Future<void> _loadMarkers() async {
    // JSON 파일을 읽어옵니다.
    String jsonString = await rootBundle.loadString('json/cafe_info.json');
    List<dynamic> jsonResponse = json.decode(jsonString);

    // JSON 데이터를 Cafe 객체 리스트로 변환합니다.
    List<Cafe> cafes = jsonResponse.map((data) => Cafe.fromJson(data)).toList();

    // 마커를 생성하여 상태에 저장합니다.
    Set<Marker> markers = await createMarkers(cafes);
    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('카공여지도'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers, // 로드된 마커들을 지도에 표시
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.center_focus_strong),
        onPressed: () {
          _goToCenter();
        },
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> _goToCenter() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _center, zoom: 11),
    ));
  }
}
