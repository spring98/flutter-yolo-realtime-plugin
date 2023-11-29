import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';

abstract class YoloRealtimePlatformInterface extends PlatformInterface {
  /// Constructs a YoloRealtimePluginPlatform.
  YoloRealtimePlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static YoloRealtimePlatformInterface _instance = MethodChannelYoloRealtime();

  /// The default instance of [YoloRealtimePlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelYoloRealtimePlugin].
  static YoloRealtimePlatformInterface get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YoloRealtimePlatformInterface] when
  /// they register themselves.
  static set instance(YoloRealtimePlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<List<BoxModel>> watchBoxes() {
    throw UnimplementedError('watchBoxes() is not implemented.');
  }

  Future<void> initializeController(Map<String, dynamic> args) {
    throw UnimplementedError('initializeController() is not implemented.');
  }
}
