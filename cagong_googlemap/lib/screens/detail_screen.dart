import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/cafe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DetailScreen extends StatefulWidget {
  final Cafe cafe;

  const DetailScreen({super.key, required this.cafe});

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.cafe.videoUrl.isNotEmpty) {
      final videoId =
          YoutubePlayerController.convertUrlToId(widget.cafe.videoUrl);
      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            strictRelatedVideos: true,
            showControls: true,
            showVideoAnnotations: false,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      // 웹 플랫폼이 아닐 경우에만 close 메서드 호출
      _controller?.close();
    } else {
      // 웹 플랫폼일 경우 대체 정리 로직
      _controller?.pauseVideo();
      _controller = null;
    }
    super.dispose();
  }

  String _getUsageTimeText(double hours) {
    if (hours == -1) return '무제한';
    if (hours == 0) return '권장X';
    return '$hours 시간';
  }

  String _getBusinessHourText(String? hours) {
    if (hours == null || hours.isEmpty || hours == '-1') {
      return '휴무';
    }
    return hours;
  }

  Widget _buildBusinessHoursTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: ['월', '화', '수', '목', '금', '토', '일']
              .map((day) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ),
        TableRow(
          children: ['월', '화', '수', '목', '금', '토', '일']
              .map((day) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          _getBusinessHourText(widget.cafe.dailyHours[day]),
                          textAlign: TextAlign.center),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCouponImage() {
    String imageName = '${widget.cafe.name}쿠폰.png';

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: 600,
        ),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Image.asset(
            'assets/images/coupons/$imageName',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildSeatingInfoTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        const TableRow(
          children: [
            TableCell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('좌석 유형',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold)))),
            TableCell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('좌석 수',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold)))),
            TableCell(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('콘센트 수',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
        ...widget.cafe.seatingTypes.map((seating) => TableRow(
              children: [
                TableCell(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child:
                            Text(seating.type, textAlign: TextAlign.center))),
                TableCell(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(seating.count.toString(),
                            textAlign: TextAlign.center))),
                TableCell(
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(seating.powerCount,
                            textAlign: TextAlign.center))),
              ],
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cafe.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.cafe.message, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Text("주소: ${widget.cafe.address}"),
              Text("가격: ${widget.cafe.price}"),
              Text("평일 이용 시간: ${_getUsageTimeText(widget.cafe.hoursWeekday)}"),
              Text("주말 이용 시간: ${_getUsageTimeText(widget.cafe.hoursWeekend)}"),
              const SizedBox(height: 20),
              const Text("영업 시간:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _buildBusinessHoursTable(),
              const SizedBox(height: 20),
              const Text("좌석 정보:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              _buildSeatingInfoTable(),
              const SizedBox(height: 20),
              if (widget.cafe.coWork == 1) ...[
                const Text("쿠폰:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildCouponImage(),
                const SizedBox(height: 20),
              ],
              if (_controller != null)
                const Text("카페 영상:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_controller != null)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                      maxHeight: 600,
                    ),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: YoutubePlayerControllerProvider(
                        controller: _controller!,
                        child: YoutubePlayer(
                          controller: _controller!,
                          aspectRatio: 9 / 16,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
