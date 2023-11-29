import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:yolo_realtime_plugin/src/platform_interface/yolo_realtime_platform_interface.dart';
import 'package:yolo_realtime_plugin/src/utils/model.dart';

class MockYoloRealtimePluginPlatform
    with MockPlatformInterfaceMixin
    implements YoloRealtimePlatformInterface {
  @override
  Future<void> initializeController(Map<String, dynamic> args) {
    // TODO: implement initializeController
    throw UnimplementedError();
  }

  @override
  Stream<List<BoxModel>> watchBoxes() {
    // TODO: implement watchBoxes
    throw UnimplementedError();
  }
}

void main() {}
