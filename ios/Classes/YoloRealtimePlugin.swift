import Flutter
import UIKit
import Foundation
import AVFoundation
import CoreML
import Vision
import CoreImage
import VideoToolbox

@available(iOS 12.0, *)
public class YoloRealtimePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yolo_realtime_plugin", binaryMessenger: registrar.messenger())
        let instance = YoloRealtimePlugin()
        
        let factory = CameraViewFactory(channel: channel)
        registrar.register(factory, withId: "camera_view")
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initializeController":
            guard let arguments = call.arguments as? [String: Any],
                  let modelPath = arguments["modelPath"] as? String,
                  let activeClassList = arguments["activeClasses"] as? [String],
                  let confThreshold = arguments["confThreshold"] as? Double else { return }
                   
            guard let modelURL = Bundle.main.url(forResource: modelPath, withExtension: "mlmodelc"),
                  let model = try? MLModel(contentsOf: modelURL) else { return }
            
            // 성공적으로 모델과 다른 파라미터를 로딩한 경우, 설정에 반영
            Constants.MODEL = model
            Constants.CONFIDENCE_THRESHOLD = Float(confThreshold)
            Constants.ACTIVE_CLASS_LABELS = activeClassList
                        
        default:
          result(FlutterMethodNotImplemented)
        }
    }
}


@available(iOS 12.0, *)
class CameraViewFactory: NSObject, FlutterPlatformViewFactory {
    private var channel: FlutterMethodChannel?
    
    init(channel: FlutterMethodChannel?) {
       self.channel = channel
    }

    // 자동으로 호출
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CameraViewContainer(frame: frame, viewId: viewId, channel: channel)
    }
}

@available(iOS 12.0, *)
class CameraViewContainer: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewId: Int64
    private let cameraView: CameraView
    
    init(frame: CGRect, viewId: Int64, channel: FlutterMethodChannel?) {
       self.frame = frame
       self.viewId = viewId
       self.cameraView = CameraView(frame: frame, channel: channel)
       super.init()
    }

    // 자동으로 호출
    func view() -> UIView {
        return cameraView
    }
}

@available(iOS 12.0, *)
class CameraView: UIView {
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var channel: FlutterMethodChannel?

    init(frame: CGRect, channel: FlutterMethodChannel?) {
        super.init(frame: frame)
        self.channel = channel
        startCamera()
    }
 
    required init?(coder: NSCoder) {
       super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = self.bounds
    }

    // Stop camera session when view is removed
    override func removeFromSuperview() {
        super.removeFromSuperview()
        captureSession?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
    }
    
    func startCamera() {
        // Create a session
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080

        // Get video capture device
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
           print("Failed to get video device")
           return
        }

        // Create input
        var videoInput: AVCaptureDeviceInput!
        do {
           videoInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
           print("Failed to create video input: \(error)")
           return
        }

        // Add input to session
        if (captureSession?.canAddInput(videoInput) == true) {
           captureSession?.addInput(videoInput)
        } else {
           print("Failed to add video input to session")
           return
        }

        // Create video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        // Add output to session
        if (captureSession?.canAddOutput(videoOutput) == true) {
           captureSession?.addOutput(videoOutput)
        } else {
           print("Failed to add video output to session")
           return
        }

        // Create preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = self.layer.bounds

        // Add preview layer to view
        self.layer.addSublayer(videoPreviewLayer!)

        // 카메라 세션 시작
        captureSession?.startRunning()
    }
}

@available(iOS 12.0, *)
extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to convert CMSampleBuffer to CVPixelBuffer")
            return
        }
        
        detect(image: pixelBuffer)
    }
}

// MARK: - CoreML 이미지 분류
@available(iOS 12.0, *)
extension CameraView {
    // CoreML의 CVPixelBuffer (이미지 주소)에 접근해 모델에 통과시킨다.
    func detect(image: CVPixelBuffer) {
        // Vision 프레임워크인 VNCoreMLModel 컨터이너를 사용하여 CoreML의 model에 접근한다.
        guard let mlModel = Constants.MODEL else { return }
        guard let visionModel = try? VNCoreMLModel(for: mlModel) else { return }
        
        // 이미치 처리를 요청
        let request = VNCoreMLRequest(model: visionModel) { [self] request, error in
            guard error == nil else {
                fatalError("Failed Request")
            }

            guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                fatalError("Faild convert VNClassificationObservation")
            }
                        
            parseObservations(observations, pixelBuffer: image)
        }
        
        // 이미지를 받아와서 perform을 요청하여 분석한다.
        let handler = VNImageRequestHandler(cvPixelBuffer: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func parseObservations(_ observations: [VNRecognizedObjectObservation], pixelBuffer: CVPixelBuffer) {
        var outerMap: [String: [String: Any]] = [:]  // 외부 맵 생성
        var image: Data?
        
        if(!observations.isEmpty) {
            image = pixelBufferToData(pixelBuffer: pixelBuffer)
        }

        for (index, observation) in observations.enumerated() {
            // CONFIDENCE_THRESHOLD와 ACTIVE_CLASS_LABELS 확인
            if observation.confidence > Constants.CONFIDENCE_THRESHOLD,
               let label = observation.labels.first?.identifier,
               Constants.ACTIVE_CLASS_LABELS.contains(label) {
                
                guard let image = image else {return}
                // bounding box 좌표를 얻습니다.
                let boundingBox = observation.boundingBox
                
                // 내부 맵을 생성합니다.
                let innerMap: [String: Any] = [
                    "x": boundingBox.origin.x,
                    "y": boundingBox.origin.y,
                    "width": boundingBox.size.width,
                    "height": boundingBox.size.height,
                    "label": observation.labels.first?.identifier ?? "Unknown",
                    "confidence": observation.confidence,
                    "image": image
                ]
                
                // 내부 맵을 외부 맵에 추가합니다.
                outerMap["box\(index)"] = innerMap
            }
        }

        // 외부 맵을 Flutter로 전송합니다.
        channel?.invokeMethod("boxes", arguments: outerMap)
    }
    
    func pixelBufferToData(pixelBuffer: CVPixelBuffer) -> Data? {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let size = CVPixelBufferGetDataSize(pixelBuffer)
        return Data(bytes: baseAddress, count: size)
    }

}

class Constants {
    // 모델
    static var MODEL: MLModel? = nil
    
    // 신뢰도 임계값
    static var CONFIDENCE_THRESHOLD: Float = 0.5
    
    // 내가 사용한 모델의 전체 클래스 리스트 중 실제로 사용할 클래스 리스트
    static var ACTIVE_CLASS_LABELS: [String] = []

}
