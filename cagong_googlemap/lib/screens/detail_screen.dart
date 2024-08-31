import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/cafe.dart';

class DetailScreen extends StatefulWidget {
  final Cafe cafe;

  const DetailScreen({Key? key, required this.cafe}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (widget.cafe.videoUrl.isNotEmpty) {
      final videoId = YoutubePlayerController.convertUrlToId(widget.cafe.videoUrl);
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
    _controller?.close();
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
                      child: Text(day, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ))
              .toList(),
        ),
        TableRow(
          children: ['월', '화', '수', '목', '금', '토', '일']
              .map((day) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_getBusinessHourText(widget.cafe.dailyHours[day]), textAlign: TextAlign.center),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSeatingInfoTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: [
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('좌석 유형', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('좌석 수', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('콘센트 수', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
        ...widget.cafe.seatingTypes.map((seating) => TableRow(
          children: [
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(seating.type, textAlign: TextAlign.center))),
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(seating.count.toString(), textAlign: TextAlign.center))),
            TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(seating.powerCount, textAlign: TextAlign.center))),
          ],
        )).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cafe.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.cafe.message, style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Text("주소: ${widget.cafe.address}"),
              Text("가격: ${widget.cafe.price}"),
              Text("평일 이용 시간: ${_getUsageTimeText(widget.cafe.hoursWeekday)}"),
              Text("주말 이용 시간: ${_getUsageTimeText(widget.cafe.hoursWeekend)}"),
              SizedBox(height: 20),
              Text("영업 시간:", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildBusinessHoursTable(),
              SizedBox(height: 20),
              Text("좌석 정보:", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildSeatingInfoTable(),
              SizedBox(height: 20),
              if (_controller != null)
                Text("카페 영상:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
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