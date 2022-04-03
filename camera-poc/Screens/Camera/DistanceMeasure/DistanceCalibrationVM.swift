//
//  DistanceCalibrationVM.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import Foundation
import AVFoundation
import ARKit

class DistanceCalibrationVM: NSObject {
    enum Step {
        case faceDistance
        case eyesDistance
        case completed
    }

    private let cameraQueue = DispatchQueue(label: "calibrate.camera.queue")
    private let router: DistanceCalibrationRouter
    private let session = AVCaptureSession()
    private let videoOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        let formatKey = kCVPixelBufferPixelFormatTypeKey as NSString
        let format = NSNumber(value: kCVPixelFormatType_32BGRA)
        output.videoSettings = [formatKey: format] as [String : Any]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    private let settings = Settings()
    private var measure: DistanceMeasure!
    private var step: Step = .faceDistance {
        didSet {
            switch step {
            case .eyesDistance:
                measureEyesDistance()
            case .faceDistance:
                break
            case .completed:
                break
            }
        }
    }
    private var faceNode = SCNNode()
    private var leftEye = SCNNode()
    private var rightEye = SCNNode()
    
    let referalDistance = 40
    
    private(set) var isStepCompleted: Bound<Bool> = Bound(false)
    private(set) var distance: Bound<Int> = Bound(0)
    
    lazy var preview = CameraPreviewView(frame: .zero)
    lazy var sceneView = ARSCNView(frame: .zero)
    
    init(router: DistanceCalibrationRouter) {
        self.router = router
    }
    
    func setup() {
        preview.videoPreviewLayer.session = session
//        preview.videoPreviewLayer.videoGravity = .resizeAspectFill
        measure = DistanceMeasure(box: preview.videoPreviewLayer)
        setupCameraSession()
    }
    
    func calibrate() {
        preview.isHidden = true
        sceneView.isHidden = false
        if session.isRunning {
            session.stopRunning()
            videoOutput.setSampleBufferDelegate(nil, queue: cameraQueue)
        }
        setupTracking()
    }
    
    func measureEyesDistance() {
        sceneView.session.pause()
        sceneView.isHidden = true
        preview.isHidden = false

        session.startRunning()
    }
}

extension DistanceCalibrationVM {
    private func setupCameraSession() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
            fatalError("No camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        session.addInput(cameraInput)
        session.addOutput(videoOutput)
        
        guard let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = .portrait
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
    }
}

extension DistanceCalibrationVM: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        Task {
            let distance = await measure.eyesDistance(in: frame)
            guard distance > 0 && distance != .infinity else { return }
            await MainActor.run {
                guard self.step == .eyesDistance else { return }
                self.isStepCompleted.value = true
                self.settings.referalEyesDistance = Int(ceil(distance))
                self.settings.referalFaceDistance = self.referalDistance
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.router.presentCamera() { [weak self] in
                        self?.session.stopRunning()
                        self?.videoOutput.setSampleBufferDelegate(nil, queue: self?.cameraQueue)
                    }
                }
                self.step = .completed
            }
        }
    }
}

extension DistanceCalibrationVM {
    private func setupTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        setupEyeNode()
    }

    private func setupEyeNode() {
        let eyeGeometry = SCNSphere(radius: 0.005)
        eyeGeometry.materials.first?.diffuse.contents = UIColor.clear
        eyeGeometry.materials.first?.transparency = 1
        
        let node = SCNNode()
        node.geometry = eyeGeometry
        node.eulerAngles.x = -.pi / 2
        node.position.z = 0.1

        leftEye = node.clone()
        rightEye = node.clone()
    }
}

extension DistanceCalibrationVM: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        faceNode = node
        faceNode.addChildNode(leftEye)
        faceNode.addChildNode(rightEye)
        faceNode.transform = node.transform

        trackDistance()
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceNode.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }

        leftEye.simdTransform = faceAnchor.leftEyeTransform
        rightEye.simdTransform = faceAnchor.rightEyeTransform

        trackDistance()
    }

    func trackDistance() {
        DispatchQueue.main.async {
            guard self.step == .faceDistance else {
                return
            }
            let leftEyeDistanceFromCamera = self.leftEye.worldPosition - SCNVector3Zero
            let rightEyeDistanceFromCamera = self.rightEye.worldPosition - SCNVector3Zero
            
            let averageDistance = (leftEyeDistanceFromCamera.length() + rightEyeDistanceFromCamera.length()) / 2
            let referalDistance = Int(round(averageDistance * 100))
            self.distance.value = referalDistance
            if referalDistance == self.referalDistance {
                self.step = .eyesDistance
            }
        }
    }
}

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }

    static func - (l: SCNVector3, r: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
    }
}
