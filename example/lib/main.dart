// ignore_for_file: prefer_const_constructors

import 'package:yolo_realtime_plugin/yolo_realtime_plugin.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(
    MaterialApp(
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => YoloRealTimeViewExample(),
                  ),
                );
              },
              child: Text('START YOLO'),
            )
          ],
        ),
      ),
    );
  }
}

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

  // Future<File?> imageToFile(Uint8List? image) async {
  //   File? file;
  //   if (image != null) {
  //     final tempDir = await getTemporaryDirectory();
  //     file = await File('${tempDir.path}/${DateTime.now()}.png').create();
  //     file.writeAsBytesSync(image);
  //
  //     print('File saved: ${file.path}');
  //   }
  //   return file;
  // }

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
