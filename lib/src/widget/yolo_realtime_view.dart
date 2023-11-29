import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';
import 'package:yolo_realtime_plugin/src/widget/box_painter.dart';

class YoloRealTimeView extends StatefulWidget {
  final YoloRealtimeController controller;
  final double width;
  final double height;
  final bool drawBox;
  final List<Color> colors;
  final void Function(Uint8List)? captureImage;
  final void Function(List<BoxModel>)? captureBox;

  const YoloRealTimeView({
    Key? key,
    required this.controller,
    required this.width,
    required this.height,
    this.drawBox = true,
    this.captureImage,
    this.captureBox,
    List<Color>? boxColors,
  })  : colors = boxColors ??
            const [
              Color(0xFFF26D6F),
              Color(0xFFF2835D),
              Color(0xFFDE3E47),
              Colors.blue,
              Color(0xFF7AB974),
              Color(0xFFFFC16E),
            ],
        super(key: key);

  @override
  State<YoloRealTimeView> createState() => _YoloRealTimeViewState();
}

class _YoloRealTimeViewState extends State<YoloRealTimeView> {
  final key = GlobalKey();
  List<BoxModel> boxes = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  // var start = DateTime.now().millisecond;
  Future<void> init() async {
    try {
      Stream<List<BoxModel>> boxStream = await widget.controller.watchBoxes();
      boxStream.listen((event) async {
        // var end = DateTime.now().millisecond;
        // print('🔥 time: ${end - start} ms, frame: ${1000 / (end - start)}');
        // start = DateTime.now().millisecond;

        boxes = [];

        if (mounted) {
          setState(() {
            for (var box in event) {
              final double x = box.rect.left;
              final double y = box.rect.top;
              final double width = box.rect.width;
              final double height = box.rect.height;
              final String label = box.label;
              final double confidence = box.confidence;

              final double screenWidth = widget.width;
              final double screenHeight = widget.height;

              final double rectX = y * screenWidth;
              final double rectY = x * screenHeight;
              final double rectWidth = height * screenWidth;
              final double rectHeight = width * screenHeight;

              boxes.add(
                BoxModel(
                  rect: Rect.fromLTWH(rectX, rectY, rectWidth, rectHeight),
                  label: label,
                  confidence: confidence,
                  image: box.image,
                ),
              );
            }

            // 감지된 이미지 전송
            if (widget.captureImage != null) {
              if (boxes.isNotEmpty) {
                widget.captureImage!(boxes.first.image);
              }
            }

            // 감지된 박스 리스트 전송
            if (widget.captureBox != null) {
              if (boxes.isNotEmpty) {
                widget.captureBox!(boxes);
              }
            }
          });
        }
      });
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget nativeView = Container();

    if (Platform.isAndroid) {
      nativeView = const AndroidView(
        viewType: 'camera_view',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      nativeView = const UiKitView(
        viewType: 'camera_view',
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    return Stack(
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: nativeView,
        ),
        if (widget.drawBox) ...[
          CustomPaint(
            painter: YoloBoxPainter(
              boxes: boxes,
              colors: widget.colors,
            ),
          ),
        ]
      ],
    );
  }
}
