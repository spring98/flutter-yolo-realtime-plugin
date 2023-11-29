import 'dart:async';
import 'package:flutter/services.dart';
import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';

/// An implementation of [YoloRealtimePlatform] that uses method channels.
class MethodChannelYoloRealtime extends YoloRealtimePlatformInterface {
  final methodChannel = const MethodChannel('yolo_realtime_plugin');
  final StreamController<List<BoxModel>> _boxesController =
      StreamController.broadcast();

  @override
  Future<void> initializeController(Map<String, dynamic> args) async {
    await methodChannel.invokeMethod('initializeController', args);
  }

  @override
  Stream<List<BoxModel>> watchBoxes() {
    methodChannel.setMethodCallHandler(pluginHandler);
    return _boxesController.stream;
  }

  Future<void> pluginHandler(MethodCall call) async {
    switch (call.method) {
      case 'boxes':
        boxesHandler(call);
        break;
      default:
        throw ('Not implemented: ${call.method}');
    }
  }

  // _handleOnDiscovered
  void boxesHandler(MethodCall call) async {
    List<BoxModel> boxes = [];
    final Map outerMap = call.arguments; // arguments를 맵으로 변환

    if (outerMap.keys.isNotEmpty) {
      for (var key in outerMap.keys) {
        final Map boundingBox = outerMap[key]; // 각 키에 대해 내부 맵을 가져옵니다.
        final double x = boundingBox['x'];
        final double y = boundingBox['y'];
        final double width = boundingBox['width'];
        final double height = boundingBox['height'];
        final String label = boundingBox['label'];
        final double confidence = boundingBox['confidence'];
        final Uint8List image = boundingBox['image'];

        boxes.add(
          BoxModel(
            rect: Rect.fromLTWH(x, y, width, height),
            label: label,
            confidence: confidence,
            image: image,
          ),
        );
      }
    }

    _boxesController.add(boxes); // 스트림에 박스 목록 추가
  }
}
