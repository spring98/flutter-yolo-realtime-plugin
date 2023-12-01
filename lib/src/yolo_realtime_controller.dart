// ignore_for_file: constant_identifier_names, slash_for_doc_comments

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
  final int? androidModelWidth;
  final int? androidModelHeight;
  final double androidConfThreshold;
  final double androidIouThreshold;

  /// iOS Only
  final String? iOSModelPath;
  final double iOSConfThreshold;

  /// The information you need to enter varies depending on the platform.
  ///
  /// Both platforms require
  /// version;
  /// fullClasses;
  /// activeClasses;
  ///
  ///
  /// On Android Platform,
  /// You must enter
  /// androidModelPath;
  /// androidModelWidth;
  /// androidModelHeight;
  /// androidConfThreshold;
  /// androidIouThreshold;
  ///
  ///
  /// On iOS Platform,
  /// You must enter
  /// iOSModelPath;
  /// iOSConfThreshold;

  YoloRealtimeController({
    required this.fullClasses,
    required this.activeClasses,
    this.version = YoloVersion.v5,
    this.androidModelPath,
    this.androidModelWidth,
    this.androidModelHeight,
    this.androidConfThreshold = 0.5,
    this.androidIouThreshold = 0.5,
    this.iOSModelPath,
    this.iOSConfThreshold = 0.5,
  });

  Future<void> initialize() async {
    /// Android
    if (Platform.isAndroid) {
      if (androidModelPath == null ||
          androidModelWidth == null ||
          androidModelHeight == null) {
        throw AssertionError('You must enter the Android parameters.');
      }

      final Map<String, dynamic> args = {
        'modelPath': androidModelPath,
        'fullClasses': fullClasses,
        'activeClasses': activeClasses,
        'version': version.toString(),
        'modelWidth': androidModelWidth,
        'modelHeight': androidModelHeight,
        'confThreshold': androidConfThreshold,
        'iouThreshold': androidIouThreshold,
      };

      YoloRealtimePlatformInterface.instance.initializeController(args);
    }

    /// iOS
    if (Platform.isIOS) {
      if (iOSModelPath == null) {
        throw AssertionError('You must enter the iOS parameters.');
      }

      final Map<String, dynamic> args = {
        'modelPath': iOSModelPath,
        'fullClasses': fullClasses,
        'activeClasses': activeClasses,
        'version': version.toString(),
        'confThreshold': iOSConfThreshold,
      };

      YoloRealtimePlatformInterface.instance.initializeController(args);
    }
  }

  Future<Stream<List<BoxModel>>> watchBoxes() async {
    return YoloRealtimePlatformInterface.instance.watchBoxes();
  }
}
