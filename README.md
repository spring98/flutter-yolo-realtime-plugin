# flutter_yolo_realtime_plugin
This is a flutter implementation that supports YOLO Realtime Object Detection.

# preview

### iPhone 13 pro
https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/b0e97003-d4f9-4a19-b0e8-c1981c6e4cb8

### Galaxy S10
https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/4da95ee3-2005-48ec-8d00-a717b2d0e8fb

## Features
* All you have to do is enter some simple information into the controller.
* The supported widget view can freely change its size, determine whether to draw a box, receive box information, and retrieve detected images.

### Platform specific setup

- **Android**

Change the minimum SDK version to 21 (or higher) in `android/app/build.gradle`:

```
minSdkVersion 21
compileSdkVersion 34
```


Libraries used (you do not need to specify them yourself):

```
dependencies {

    // PyTorch dependencies
    implementation 'org.pytorch:pytorch_android:1.8.0'
    implementation 'org.pytorch:pytorch_android_torchvision:1.8.0'
    implementation 'androidx.camera:camera-lifecycle:1.3.0'

    // CameraX core library
    implementation "androidx.camera:camera-core:1.3.0"
    implementation "androidx.camera:camera-camera2:1.3.0"
    implementation "androidx.camera:camera-lifecycle:1.3.0"
    implementation 'androidx.camera:camera-view:1.3.0'

    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.android.support:multidex:1.0.3'

}
```


- **iOS**

Add these on `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos.</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to record audio.</string>
```

Change the Minumum Deployment iOS 12 (or higher) `Runner/Minumum Deployments`


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

### 1. Model preparation

### 2. Positioning the model well on the path
**For Android, you can add the model as if you were adding it to flutter assets, 
but for iOS, you need to turn on xcode and drag it directly to Runner > Runner and copy it, which becomes the root path.**
<br/>
#### 2-1. Android
<img width="280" alt="스크린샷 2023-12-02 04 51 45" src="https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/e0bb1e0b-2f8c-42eb-8515-f95504490f04">
<br/>
<img width="719" alt="스크린샷 2023-12-02 04 54 58" src="https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/de8b4ee7-cd47-49de-a5de-8a4323006705">

#### 2-2. iOS
<img width="369" alt="스크린샷 2023-12-02 04 50 12" src="https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/7559ca88-ab31-4988-a2a7-ba93b9e41232">
<br/>
Runner > Runner > your_custom_model.mlmodel
<br/>
<br/>

<img width="865" alt="스크린샷 2023-12-02 04 49 59" src="https://github.com/spring98/flutter-yolo-realtime-plugin/assets/92755385/eed42bb3-5cdd-4ec3-ab6b-aa0c28cf1287">
<br/>
Just drag and copy the model and the class labels will come out like this.
<br/>


### 3. Code Example:

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


