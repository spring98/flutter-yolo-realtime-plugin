@file:Suppress("LocalVariableName", "PrivatePropertyName")

package com.spring98.yolo_realtime_plugin

import android.Manifest
import android.R.attr.bitmap
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.*
import android.util.Log
import android.view.View
import androidx.annotation.OptIn
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.spring98.yolo_realtime_plugin.Constants.Companion.ACTIVE_CLASS_LABELS
import com.spring98.yolo_realtime_plugin.Constants.Companion.CONFIDENCE_THRESHOLD
import com.spring98.yolo_realtime_plugin.Constants.Companion.DETECTION_SIZE
import com.spring98.yolo_realtime_plugin.Constants.Companion.FULL_CLASS_LABELS
import com.spring98.yolo_realtime_plugin.Constants.Companion.IOU_THRESHOLD
import com.spring98.yolo_realtime_plugin.Constants.Companion.MODEL
import com.spring98.yolo_realtime_plugin.Constants.Companion.MODEL_INPUT_SIZE
import com.spring98.yolo_realtime_plugin.Constants.Companion.PADDING_SIZE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.PyTorchAndroid
import org.pytorch.torchvision.TensorImageUtils
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors


/** YoloRealtimePlugin */
class YoloRealtimePlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var binding: FlutterPlugin.FlutterPluginBinding
  private var activity: Activity? = null

  private val CAMERA_REQUEST_CODE = 100 // 카메라 요청 코드

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.binding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "yolo_realtime_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    // 카메라 트리거 처리
    when (call.method) {
      "initializeController" -> {
        val arguments = call.arguments as? Map<*, *> ?: return
        val modelPath = arguments["modelPath"] as? String
        val fullClassList = arguments["fullClassList"] as? List<*>
        val activeClassList = arguments["activeClassList"] as? List<*>
        val version = arguments["version"] as? String
        val modelInputSize = arguments["modelInputSize"] as? String
        val confThreshold = arguments["confThreshold"] as? Double
        val iouThreshold = arguments["iouThreshold"] as? Double

//          Log.d("[SPRING]", "Yolo controller initialized: $modelPath, $fullClassList, $activeClassList, $version, $modelInputSize, $confThreshold, $iouThreshold")

        when (modelInputSize) {
          // input size 가 320 일 때
          "ModelInputSize.SIZE_320" -> {
            PADDING_SIZE = 40
            MODEL_INPUT_SIZE = 320
          }

          // input size 가 640 일 때
          "ModelInputSize.SIZE_640" -> {
            PADDING_SIZE = 80
            MODEL_INPUT_SIZE = 640
          }
        }

        DETECTION_SIZE = fullClassList?.size?.plus(5) ?: 0
        CONFIDENCE_THRESHOLD = confThreshold ?: 0.0
        IOU_THRESHOLD = iouThreshold ?: 0.0
        FULL_CLASS_LABELS = fullClassList?.filterIsInstance<String>()?.toMutableList() ?: mutableListOf()
        ACTIVE_CLASS_LABELS = activeClassList?.filterIsInstance<String>()?.toMutableList() ?: mutableListOf()

        val assetKey = binding.flutterAssets.getAssetFilePathByName(modelPath ?: "")
        MODEL = PyTorchAndroid.loadModuleFromAsset(binding.applicationContext.assets, assetKey)
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // 이 메서드는 플러그인이 Flutter 엔진에 연결된 후, 플러그인이 호스팅하는 액티비티에 첫 번째로 연결될 때 호출됩니다.
  // 이 시점에서 플러그인은 액티비티와의 상호작용을 설정할 수 있습니다.
  // 예를 들어, 액티비티의 컨텍스트를 사용하여 네이티브 기능을 구현하거나, 액티비티의 생명주기 이벤트를 수신할 수 있습니다.
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity

    activity?.let {
      this.binding.platformViewRegistry.registerViewFactory(
        "camera_view", CameraViewFactory(it, channel)
      )
    }

    checkCameraPermission()
    binding.addRequestPermissionsResultListener { requestCode, _, grantResults ->
      when (requestCode) {
        CAMERA_REQUEST_CODE -> {
          if ((grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)) {
            // 권한이 허용됨
            Log.d("[SPRING]", "Allow permission")
          } else {
            // 권한이 거부됨
            Log.d("[SPRING]", "Permission denied")
          }
        }
      }
      true
    }
  }

  // 이 메서드는 구성 변경(예: 화면 회전)으로 인해 액티비티가 재생성되기 전에 호출됩니다.
  // 이 시점에서 플러그인은 액티비티와의 연결을 일시적으로 해제하고, 필요한 정리 작업을 수행할 수 있습니다.
  // 구성 변경 후에는 onReattachedToActivityForConfigChanges가 호출됩니다.
  override fun onDetachedFromActivityForConfigChanges() {}

  // 이 메서드는 구성 변경 후에 새로 생성된 액티비티에 플러그인이 다시 연결될 때 호출됩니다.
  // 이 메서드는 플러그인이 새 액티비티 인스턴스와 상호작용을 재설정할 수 있는 기회를 제공합니다.
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

  // 이 메서드는 플러그인이 액티비티와의 연결이 완전히 해제될 때 호출됩니다.
  // 이는 액티비티가 파괴되거나 플러그인이 Flutter 엔진으로부터 분리될 때 발생할 수 있습니다.
  // 이 시점에서 플러그인은 액티비티와의 모든 상호작용을 정리하고, 필요한 리소스를 해제해야 합니다.
  override fun onDetachedFromActivity() {}

  private fun checkCameraPermission() {
    if (ContextCompat.checkSelfPermission(activity!!, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
      ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.CAMERA), CAMERA_REQUEST_CODE)
    }
  }

}


class CameraViewFactory(
  private val activity: Activity,
  private val channel: MethodChannel,
) :
  PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    return CameraView(context, activity, channel)
  }
}

class CameraView(
  private val context: Context,
  private val activity: Activity,
  private val channel: MethodChannel,
) : PlatformView {
  private var cameraProvider: ProcessCameraProvider? = null
  private val previewView = PreviewView(context)

  init {
    setupCamera()
  }

  override fun dispose() {
    cameraProvider?.unbindAll()
  }

  private fun setupCamera() {
    previewView.scaleType = PreviewView.ScaleType.FILL_CENTER
    previewView.implementationMode = PreviewView.ImplementationMode.COMPATIBLE

    val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    cameraProviderFuture.addListener({
      this.cameraProvider = cameraProviderFuture.get()

      // 단일 스레드 사용
      val executor = Executors.newSingleThreadExecutor()
      // 고정된 스레드 풀 사용
      // val executor = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())

      // Create a Preview
      val preview = Preview.Builder()
        .build()

      val imageAnalyzer = ImageAnalysis.Builder()
        .build()
        .also {
          it.setAnalyzer(executor, YoloImageAnalyzer())
        }

      // Select the back camera
      val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

      // Unbind any bound use cases before rebinding
      cameraProvider?.unbindAll()

      // Bind the Preview use case to the camera provider
      try {
        cameraProvider?.bindToLifecycle(
          activity as LifecycleOwner,
          cameraSelector,
          preview,
          imageAnalyzer
        )

        // Connect the preview use case to the preview view
        preview.setSurfaceProvider(previewView.surfaceProvider)

        // 카메라가 성공적으로 열렸음을 나타내는 로그
        Log.d("[SPRING]", "카메라가 성공적으로 열렸습니다.")

      } catch (exc: Exception) {
        Log.e("[SPRING]", "카메라 사용 중 오류 발생: ${exc.localizedMessage}")
      }
    }, ContextCompat.getMainExecutor(context))

  }

  override fun getView(): View {
    return previewView
  }

  private inner class YoloImageAnalyzer : ImageAnalysis.Analyzer {
    @OptIn(ExperimentalGetImage::class)
    override fun analyze(image: ImageProxy) {
      if(MODEL == null) {
        image.close()
        return
      }

      // 이미지를 Bitmap 으로 변환
      val bitmap_origin = image.toBitmap()

      // 640 * 480
      val bitmap640_480 =
        Bitmap.createBitmap(bitmap_origin, 0, 0, bitmap_origin.width, bitmap_origin.height, Matrix(), true)

      // 320 * 240 or 640 * 480
      val resize320_240 =
        Bitmap.createScaledBitmap(bitmap640_480, MODEL_INPUT_SIZE, MODEL_INPUT_SIZE - 2*PADDING_SIZE, true)

      // 320 * 320 or 640 * 640
      val zeroPadding320_320 =
        resize320_240.addPadding(Color.BLACK, 0, PADDING_SIZE, 0, PADDING_SIZE)

      // Bitmap To Tensor
      val inputTensor = TensorImageUtils.bitmapToFloat32Tensor(
        zeroPadding320_320,

        // NO_MEAN_RGB
        floatArrayOf(0.0f, 0.0f, 0.0f),

        // NO_STD_RGB
        floatArrayOf(1.0f, 1.0f, 1.0f)
      )

      // Tensor -> FloatArray
      val outputTensor = MODEL!!.forward(IValue.from(inputTensor)).toTuple()[0].toTensor().dataAsFloatArray

      // 결과 처리 (예: 객체 위치, 신뢰도 등)
      val detectionResults = processOutput(outputTensor)

      val nmsDetectionResults = nms(detectionResults, IOU_THRESHOLD)

      // 추론 결과에 따라 필요한 작업 수행
      sendToFlutter(nmsDetectionResults, bitmap_origin) // Flutter로 결과 전송

      // 이미지 리소스 해제
      image.close()
    }

    private fun sendToFlutter(results: List<DetectionResult>, image: Bitmap) {
      val thread = Thread {
        try {
          val stream = ByteArrayOutputStream()
          image.compress(Bitmap.CompressFormat.JPEG, 100, stream)
          val byteArray: ByteArray = stream.toByteArray()

          val outerMap = results.mapIndexed { index, result ->
            "box$index" to mapOf(
              "x" to result.boundingBox.left,
              "y" to result.boundingBox.top,
              "width" to result.boundingBox.width,
              "height" to result.boundingBox.height,
              "label" to result.label,
              "confidence" to result.confidence,
               "image" to byteArray // 이 부분은 필요에 따라 조정
            )
          }.toMap()

          activity.runOnUiThread {
//            Log.d("[SPRING]", outerMap.toString())
            channel.invokeMethod("boxes", outerMap)
          }
        } catch (e: Exception) {
          e.printStackTrace()
        }
      }
      thread.start()
    }

    private fun Bitmap.addPadding(
      color: Int = Color.BLACK,
      left: Int = 0,
      top: Int = 0,
      right: Int = 0,
      bottom: Int = 0
    ): Bitmap {
      val bitmap = Bitmap.createBitmap(
        width + left + right, // width in pixels
        height + top + bottom, // height in pixels
        Bitmap.Config.ARGB_8888
      )
      val canvas = Canvas(bitmap)
      canvas.drawColor(color)
      Paint().apply {
        xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
        canvas.drawRect(
          Rect(left, top, bitmap.width - right, bitmap.height - bottom),
          this
        )
      }
      Paint().apply {
        canvas.drawBitmap(
          this@addPadding, // bitmap
          0f + left, // left
          0f + top, // top
          this // paint
        )
      }
      return bitmap
    }

    private fun processOutput(tensor: FloatArray): List<DetectionResult> {
      val results = mutableListOf<DetectionResult>()

      // tensor.size = 535500 / 85 = 6300
      for (i in tensor.indices step DETECTION_SIZE) {
        val confidence = tensor[i + 4]
        if (confidence > CONFIDENCE_THRESHOLD) {
          val x: Float = tensor[i]
          val y: Float = convertRange(tensor[i + 1])
          val w: Float = tensor[i + 2]
          val h: Float = tensor[i + 3] * (MODEL_INPUT_SIZE + 2*PADDING_SIZE).toFloat()/(MODEL_INPUT_SIZE - 2*PADDING_SIZE)

          val left = (x - w / 2) / MODEL_INPUT_SIZE
          val top = ((MODEL_INPUT_SIZE - y - h / 2) / MODEL_INPUT_SIZE)
          val width = w / MODEL_INPUT_SIZE
          val height = (h / MODEL_INPUT_SIZE)

          var maxClassScore = tensor[i + 5]
          var cls = 0
          for (j in 0 until DETECTION_SIZE - 5) {
            if (tensor[i + 5 + j] > maxClassScore) {
              maxClassScore = tensor[i + 5 + j]
              cls = j
            }
          }

          val rect = RectLTWH(left, top, width, height)

          // ACTIVE_CLASS_LABELS에 label이 포함되어 있으면 label을 리턴
          if (getClassLabel(cls) in ACTIVE_CLASS_LABELS) {
            results.add(DetectionResult(rect, getClassLabel(cls), confidence))
          }
        }
      }

      return results
    }

    fun convertRange(originalValue: Float): Float {
      val originalMin = PADDING_SIZE.toFloat()
      val originalMax = MODEL_INPUT_SIZE.toFloat() - PADDING_SIZE.toFloat()
      val newMin = - PADDING_SIZE.toFloat()
      val newMax = MODEL_INPUT_SIZE.toFloat() + PADDING_SIZE.toFloat()

      return ((originalValue - originalMin) / (originalMax - originalMin)) * (newMax - newMin) + newMin
    }

    // 클래스 라벨을 얻는 함수 (클래스 인덱스를 클래스 이름으로 변환)
    private fun getClassLabel(classIndex: Int): String {
      return FULL_CLASS_LABELS[classIndex]
    }
  }

  fun nms(boxes: List<DetectionResult>, iouThreshold: Double): List<DetectionResult> {
    if (boxes.isEmpty()) return emptyList()

    val sortedBoxes = boxes.sortedByDescending { it.confidence }
    val selectedBoxes = mutableListOf<DetectionResult>()

    for (box in sortedBoxes) {
      var shouldSelect = true
      for (selectedBox in selectedBoxes) {
        if (iou(box.boundingBox.toRectF(), selectedBox.boundingBox.toRectF()) > iouThreshold) {
          shouldSelect = false
          break
        }
      }
      if (shouldSelect) {
        selectedBoxes.add(box)
      }
    }

    return selectedBoxes
  }

  private fun iou(boxA: RectF, boxB: RectF): Float {
    val intersectionArea = (boxA.right.coerceAtMost(boxB.right) - boxA.left.coerceAtLeast(boxB.left)).coerceAtLeast(0f) *
            (boxA.bottom.coerceAtMost(boxB.bottom) - boxA.top.coerceAtLeast(boxB.top)).coerceAtLeast(0f)

    val boxAArea = (boxA.right - boxA.left) * (boxA.bottom - boxA.top)
    val boxBArea = (boxB.right - boxB.left) * (boxB.bottom - boxB.top)

    val unionArea = boxAArea + boxBArea - intersectionArea

    return if (unionArea > 0f) intersectionArea / unionArea else 0f
  }

  // RectLTWH 클래스의 확장 함수로 RectF 변환
  private fun RectLTWH.toRectF(): RectF {
    return RectF(left, top, left + width, top + height)
  }
}

data class DetectionResult(
  val boundingBox: RectLTWH,  // 객체의 위치 및 크기를 나타내는 경계 상자
  val label: String,       // 객체의 클래스 라벨
  val confidence: Float    // 객체 감지에 대한 신뢰도
)

class RectLTWH (
  left:Float,
  top:Float,
  width:Float,
  height:Float,
) {
  val left = left.coerceIn(0.0f, 1.0f)
  val top = top.coerceIn(0.0f, 1.0f)
  private val right = (left + width).coerceIn(0.0f, 1.0f)
  private val bottom = (top + height).coerceIn(0.0f, 1.0f)
  val width = right - this.left
  val height = bottom - this.top
}


class Constants {
  // 상수 정의
  companion object {
    // 각 탐지에 대한 정보 개수 80 + 5 = (x, y, width, height, confidence, 클래스 개수)
    var DETECTION_SIZE:Int = 85

    // 신뢰도 임계값
    var CONFIDENCE_THRESHOLD:Double = 0.5

    // 신뢰도 임계값
    var IOU_THRESHOLD:Double = 0.5

    // 모델 입력 크기 640 or 320
    var MODEL_INPUT_SIZE:Int = 320

    // 모델 크기에 맞출 패딩 크기 80 or 40
    var PADDING_SIZE:Int = 40

    // 내가 사용한 모델의 전체 클래스 리스트
    var FULL_CLASS_LABELS: MutableList<String> = mutableListOf()

    // 내가 사용한 모델의 전체 클래스 리스트 중 실제로 사용할 클래스 리스트
    var ACTIVE_CLASS_LABELS:MutableList<String> = mutableListOf()

    var MODEL: Module? = null
  }

}
