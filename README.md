# preview

### iPhone 13 pro
https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/b0e97003-d4f9-4a19-b0e8-c1981c6e4cb8

### Galaxy S10
https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/4da95ee3-2005-48ec-8d00-a717b2d0e8fb

# flutter_yolo_realtime_plugin
This is a flutter implementation that supports YOLO Realtime Object Detection.

## Features
* All you have to do is enter some simple information into the controller.
* The supported widget view can freely change its size, determine whether to draw a box, receive box information, and retrieve detected images.

## Install
In the `pubspec.yaml` of your flutter project, add the following dependency:

```yaml
dependencies:
  flutter_yolo_realtime_plugin: <latest_version>
```

In your library add the following import:

```dart
import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';
```

## Getting started

Example:

```dart
class YoloRealTimeViewExample extends StatefulWidget {
  const YoloRealTimeViewExample({Key? key}) : super(key: key);

  @override
  State<YoloRealTimeViewExample> createState() =>
      _YoloRealTimeViewExampleState();
}

class _YoloRealTimeViewExampleState extends State<YoloRealTimeViewExample> {
  YoloRealtimeController? yoloController;

  @override
  void initState() {
    super.initState();

    yoloInit();
  }

  Future<void> yoloInit() async {
    yoloController = YoloRealtimeController(
      // common
      fullClasses: fullClasses,
      activeClasses: activeClasses,

      // android
      androidModelPath: 'assets/models/yolov5s_320.pt',
      androidModelWidth: 320,
      androidModelHeight: 320,
      androidConfThreshold: 0.5,
      androidIouThreshold: 0.5,

      // ios
      iOSModelPath: 'yolov5s',
      iOSConfThreshold: 0.5,
    );

    try {
      await yoloController?.initialize();
    } catch (e) {
      print('ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (yoloController == null) {
      return Container();
    }

    return YoloRealTimeView(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      controller: yoloController!,
      drawBox: true,
      captureBox: (boxes) {
        // print(boxes);
      },
      captureImage: (data) async {
        // print('binary image: $data');

        /// Process and use the binary image as you wish.
        // imageToFile(data);
      },
    );
  }

  List<String> activeClasses = [
    "car",
    "person",
    "tv",
    "laptop",
    "mouse",
    "bottle",
    "cup",
    "keyboard",
    "cell phone",
  ];

  List<String> fullClasses = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "couch",
    "potted plant",
    "bed",
    "dining table",
    "toilet",
    "tv",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush"
  ];
}
```

## Issue

You can read the FAQ here: [https://github.com/spring98/flutter-yolo-realtime-plugin/issues](https://github.com/spring98/flutter-yolo-realtime-plugin/issues)


