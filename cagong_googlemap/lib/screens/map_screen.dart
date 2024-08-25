import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'bottom_sheet_content.dart'; // 바텀 시트 UI를 위한 파일

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkersFromJson();
  }

  Future<void> _loadMarkersFromJson() async {
    // assets에서 JSON 파일을 불러옵니다.
    String jsonData = await rootBundle.loadString('assets/json/cafe_info.json');
    final List<dynamic> data = jsonDecode(jsonData);

    // JSON 데이터를 기반으로 마커를 생성합니다.
    for (var item in data) {
      _markers.add(
        Marker(
          markerId: MarkerId(item['ID'].toString()),
          position: LatLng(item['Position (Latitude)'], item['Position (Longitude)']),
          infoWindow: InfoWindow(title: item['Name']),
          onTap: () {
            _showBottomSheet(
              context,
              item['Name'],
              item['Message'],
              item['Address'],
              item['Price'],
              item['영업 시간'],
              item['Video URL'],
              item['Seating Type 1'],
              item['Seating Count 1'],
              item['Power Count 1'],
              item['Seating Type 2'],
              item['Seating Count 2'],
              item['Power Count 2'],
              item['Seating Type 3'],
              item['Seating Count 3'],
              item['Power Count 3'],
            );
          },
        ),
      );
    }

    // 상태를 갱신하여 마커를 지도에 표시합니다.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map with Bottom Sheet'),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(37.5867, 126.9963), // 첫 번째 카페 위치로 초기 카메라 위치 설정
          zoom: 15,
        ),
        markers: _markers,
      ),
    );
  }

  void _showBottomSheet(
      BuildContext context,
      String name,
      String message,
      String address,
      String price,
      String hours,
      String videoUrl,
      String? seatingType1,
      double? seatingCount1,
      String? powerCount1,
      String? seatingType2,
      double? seatingCount2,
      String? powerCount2,
      String? seatingType3,
      double? seatingCount3,
      String? powerCount3,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomSheetContent(
          name: name,
          message: message,
          address: address,
          price: price,
          hours: hours,
          videoUrl: videoUrl,
          seatingType1: seatingType1,
          seatingCount1: seatingCount1,
          powerCount1: powerCount1,
          seatingType2: seatingType2,
          seatingCount2: seatingCount2,
          powerCount2: powerCount2,
          seatingType3: seatingType3,
          seatingCount3: seatingCount3,
          powerCount3: powerCount3,
        );
      },
    );
  }
}
