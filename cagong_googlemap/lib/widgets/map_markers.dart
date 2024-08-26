import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import '../models/cafe.dart';

Future<BitmapDescriptor> resizeMarkerImage(
    String assetPath, int width, int height) async {
  // 1. 에셋에서 이미지 바이트 로드
  ByteData data = await rootBundle.load(assetPath);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  ui.FrameInfo fi = await codec.getNextFrame();

  // 2. 이미지 리사이즈
  img.Image image = img.decodeImage(data.buffer.asUint8List())!;
  img.Image resizedImage = img.copyResize(image, width: width, height: height);

  // 3. 리사이즈된 이미지를 Uint8List로 변환
  Uint8List resizedImageData = Uint8List.fromList(img.encodePng(resizedImage));

  // 4. BitmapDescriptor 생성 및 반환
  return BitmapDescriptor.fromBytes(resizedImageData);
}

Future<Set<Marker>> createMarkers(List<Cafe> cafes) async {
  // 커스텀 마커 아이콘 로드 및 리사이즈
  BitmapDescriptor customIcon =
      await resizeMarkerImage('images/marker.png', 25, 25);

  // Cafe 리스트를 순회하며 마커 생성
  Set<Marker> markers = cafes.map((cafe) {
    return Marker(
      markerId: MarkerId(cafe.id.toString()),
      position: LatLng(cafe.latitude, cafe.longitude),
      infoWindow: InfoWindow(
        title: cafe.name,
        snippet: cafe.message,
      ),
      icon: customIcon, // 리사이즈된 커스텀 마커 아이콘 설정
    );
  }).toSet();

  return markers;
}


////////////////////////////////////////////////////////////////
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../models/cafe.dart';

// class CustomMarkerGenerator {
//   static Future<BitmapDescriptor> createCustomMarkerBitmap(Cafe cafe) async {
//     final Widget markerWidget = CustomMarkerWidget(cafe: cafe);
//     final key = GlobalKey();
//     final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;

//     final render = Build(
//       key: key,
//       widget: RepaintBoundary(
//         key: key,
//         child: markerWidget,
//       ),
//     );

//     final pngBytes = await render.toPngBytes(pixelRatio);
//     return BitmapDescriptor.fromBytes(pngBytes);
//   }
// }

// class CustomMarkerWidget extends StatelessWidget {
//   final Cafe cafe;

//   CustomMarkerWidget({required this.cafe});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 3,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             cafe.name,
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
//           ),
//           Text(
//             'Weekday: ${cafe.hoursWeekday}',
//             style: TextStyle(fontSize: 10),
//           ),
//           Text(
//             'Weekend: ${cafe.hoursWeekend}',
//             style: TextStyle(fontSize: 10),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class Build {
//   final GlobalKey key;
//   final Widget widget;

//   Build({required this.key, required this.widget});

//   Future<Uint8List> toPngBytes(double pixelRatio) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

//     final RenderView renderView = RenderView(
//       child: RenderPositionedBox(child: repaintBoundary),
//       configuration: ViewConfiguration(
//         size: Size.infinite,
//         offset: Offset.zero,
//       ),
//     );

//     final PipelineOwner pipelineOwner = PipelineOwner();
//     final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

//     pipelineOwner.rootNode = renderView;
//     renderView.prepareInitialFrame();

//     final RenderObjectToWidgetElement<RenderBox> rootElement =
//         RenderObjectToWidgetAdapter<RenderBox>(
//       container: repaintBoundary,
//       child: widget,
//     ).attachToRenderTree(buildOwner);

//     buildOwner.buildScope(rootElement);
//     buildOwner.finalizeTree();

//     pipelineOwner.flushLayout();
//     pipelineOwner.flushCompositingBits();
//     pipelineOwner.flushPaint();

//     final ui.Image image =
//         await repaintBoundary.toImage(pixelRatio: pixelRatio);
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);

//     return byteData!.buffer.asUint8List();
//   }
// }
