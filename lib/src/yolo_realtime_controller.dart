import 'package:yolo_realtime_plugin/yolo_realtime.dart';
import 'dart:io';

enum YoloVersion {
  v5,
}

enum ModelInputSize {
  SIZE_320,
  SIZE_640,
}

class YoloRealtimeController {
  final YoloVersion version;
  final ModelInputSize modelInputSize;
  final String? androidModelPath;
  final String? iOSModelPath;
  final double confThreshold;
  final double iouThreshold;
  final List<String> fullClassList;
  final List<String> activeClassList;

  YoloRealtimeController({
    required this.fullClassList,
    required this.activeClassList,
    this.androidModelPath,
    this.iOSModelPath,
    this.version = YoloVersion.v5,
    this.modelInputSize = ModelInputSize.SIZE_320,
    this.confThreshold = 0.5,
    this.iouThreshold = 0.5,
  });

  Future<void> initialize() async {
    String? model;
    if (Platform.isAndroid) {
      model = androidModelPath;
    } else if (Platform.isIOS) {
      model = iOSModelPath;
    }

    if (model == null) {
      throw AssertionError('You must enter the model path.');
    }

    final Map<String, dynamic> args = {
      'modelPath': model,
      'fullClassList': fullClassList,
      'activeClassList': activeClassList,
      'version': version.toString(),
      'modelInputSize': modelInputSize.toString(),
      'confThreshold': confThreshold,
      'iouThreshold': iouThreshold,
    };

    YoloRealtimePlatformInterface.instance.initializeController(args);
  }

  Future<Stream<List<BoxModel>>> watchBoxes() async {
    return YoloRealtimePlatformInterface.instance.watchBoxes();
  }
}
