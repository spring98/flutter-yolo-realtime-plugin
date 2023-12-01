// ignore_for_file: constant_identifier_names

import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';
import 'dart:io';

enum YoloVersion {
  v5,
}

enum ModelInputSize {
  SIZE_320,
  SIZE_640,
}

class YoloRealtimeController {
  /// Android, iOS Common
  final YoloVersion version;
  final List<String> fullClasses;
  final List<String> activeClasses;

  /// Android Only
  final String? androidModelPath;
  final int androidModelWidth;
  final int androidModelHeight;
  final double androidConfThreshold;
  final double androidIouThreshold;

  /// iOS Only
  final String? iOSModelPath;
  final double iOSConfThreshold;

  YoloRealtimeController({
    required this.fullClasses,
    required this.activeClasses,
    required this.androidModelWidth,
    required this.androidModelHeight,
    this.androidModelPath,
    this.iOSModelPath,
    this.version = YoloVersion.v5,
    this.androidConfThreshold = 0.5,
    this.iOSConfThreshold = 0.5,
    this.androidIouThreshold = 0.5,
  });

  Future<void> initialize() async {
    String? model;
    double? confThreshold;

    if (Platform.isAndroid) {
      model = androidModelPath;
      confThreshold = androidConfThreshold;
    } else if (Platform.isIOS) {
      model = iOSModelPath;
      confThreshold = iOSConfThreshold;
    }

    if (model == null) {
      throw AssertionError('You must enter the model path.');
    }

    if (confThreshold == null) {
      throw AssertionError('You must enter the confidence.');
    }

    final Map<String, dynamic> args = {
      'modelPath': model,
      'fullClasses': fullClasses,
      'activeClasses': activeClasses,
      'version': version.toString(),
      'modelWidth': androidModelWidth,
      'modelHeight': androidModelHeight,
      'confThreshold': confThreshold,
      'iouThreshold': androidIouThreshold,
    };

    YoloRealtimePlatformInterface.instance.initializeController(args);
  }

  Future<Stream<List<BoxModel>>> watchBoxes() async {
    return YoloRealtimePlatformInterface.instance.watchBoxes();
  }
}
