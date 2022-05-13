//
//  CameraSDK.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import Foundation
import AVFoundation
import UIKit

protocol CameraSDKDelegate: AnyObject {
    func sessionDidStart()
    func updateDistance(_ distance: Int)
    func updateLuminosity(_ luminosity: Int)
}

class CameraSDK: NSObject {
    private enum Setting {
        case iso, exposure, shutterSpeed, whiteBalance, usv, none
    }
    
    private let kExposureDurationPower = 5.0 // Higher numbers will give the slider more sensitivity at shorter durations
    private let kExposureMinimumDuration = 1.0 / 1000 // Limit exposure duration to a useful range
    private let cameraQueue = DispatchQueue(label: "calibrate.camera.sdk.queue")
    private let router: CameraRouting
    private let settings = Settings()
    private var measure: DistanceMeasure!
    private var videoInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice!
    private var distances: [Int] = []
    private(set) var isInitialized: Bool = false
    private(set) var defaultISO: Float!
    private(set) var defaultShutterSpeed: Float!
    private(set) var defaultTint: Float!
    private(set) var defaultTemperature: Float!
    
    private let videoOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        let formatKey = kCVPixelBufferPixelFormatTypeKey as NSString
        let format = NSNumber(value: kCVPixelFormatType_32BGRA)
        output.videoSettings = [formatKey: format] as [String : Any]
        output.alwaysDiscardsLateVideoFrames = true
        return output
    }()
    let photoOutput = AVCapturePhotoOutput()
    private let captureSession: AVCaptureSession = AVCaptureSession()
    
    private var currentDistance: Int {
        let sum = self.distances.reduce(0, +)
        let distance = Float(sum) / Float(self.distances.count)
        let average = ceil(distance)
        if average > 0 && average != .infinity {
            return Int(average)
        }
        return 0
    }
    var minISO: Float {
        return videoDevice.activeFormat.minISO
    }
    
    var maxISO: Float {
        return videoDevice.activeFormat.maxISO
    }
    
    var iso: Float {
        return videoDevice.iso
    }
    
    var minShutterSpeed: Float {
        return 0.0
    }
    
    var maxShutterSpeed: Float {
        return 0.6
    }
    
    var shutterSpeed: Float {
        let exposureDurationSeconds = CMTimeGetSeconds(videoDevice.exposureDuration)
        let minExposureDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxExposureDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        // Map from duration to non-linear UI range 0-1
        let p = (exposureDurationSeconds - minExposureDurationSeconds) / (maxExposureDurationSeconds - minExposureDurationSeconds) // Scale to 0-1
        return Float(pow(p, 1 / kExposureDurationPower))
    }
    
    var aperture: Float {
        return videoDevice.lensAperture
    }
    
    var speed: Float {
        let time = videoDevice.exposureDuration
        return Float(CMTimeGetSeconds(time))
    }
    
    var minTint: Float {
        return -150
    }
    
    var maxTint: Float {
        return 150
    }
    
    var tint: Float {
        let whiteBalanceGains = videoDevice.deviceWhiteBalanceGains
        let whiteBalanceTemperatureAndTint = videoDevice.temperatureAndTintValues(for: whiteBalanceGains)

        return whiteBalanceTemperatureAndTint.tint
    }
    
    var minTemperature: Float {
        return 3000
    }
    
    var maxTemperature: Float {
        return 8000
    }
    
    var temperature: Float {
        let whiteBalanceGains = videoDevice.deviceWhiteBalanceGains
        let whiteBalanceTemperatureAndTint = videoDevice.temperatureAndTintValues(for: whiteBalanceGains)

        return whiteBalanceTemperatureAndTint.temperature
    }
    
    weak var delegate: CameraSDKDelegate?
    
    init(router: CameraRouting) {
        self.router = router
    }
    
    func start() {
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        captureSession.startRunning()
    }
    
    func pause() {
        captureSession.stopRunning()
        videoOutput.setSampleBufferDelegate(nil, queue: cameraQueue)
    }
    
    
    func requestCameraAccess(_ previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.session = self.captureSession
        previewLayer.videoGravity = .resizeAspectFill
        self.measure = DistanceMeasure(box: previewLayer)
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.setupCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setupCaptureSession()
                    }
                }
            case .denied:
                self.router.presentCameraDeniedAlert()
            case .restricted: // The user can't grant access due to restrictions.
                return
            @unknown default:
                assertionFailure("Not known camera state")
        }
    }
    
    func setupCaptureSession() {
        captureSession.beginConfiguration()
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            assertionFailure("Can't access front video camera")
            return
        }
        self.videoDevice = videoDevice
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                self.videoInput = videoInput
            }
        } catch {
            assertionFailure("Can't add video input")
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.sessionPreset = .photo
            captureSession.addOutput(photoOutput)
        }
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = .portrait
        captureSession.commitConfiguration()
        captureSession.startRunning()
        setup()
    }
    
    func changeISO(_ value: Float) throws {
        try videoDevice.lockForConfiguration()
        videoDevice.setExposureModeCustom(
            duration: AVCaptureDevice.currentExposureDuration,
            iso: value
        )
        videoDevice.unlockForConfiguration()
    }
    
//    func changeExposure(duration: Float, iso: Float) throws {
//        try videoDevice.lockForConfiguration()
//        videoDevice.setExposureModeCustom(
//            duration: exposureDuration(duration),
//            iso: iso
//        )
//        videoDevice.unlockForConfiguration()
//    }
    
    func changeExposure(_ value: Float) throws {
        try videoDevice.lockForConfiguration()
        videoDevice.setExposureTargetBias(value)
        videoDevice.unlockForConfiguration()
    }
    
    func changeWhiteBalance(tint: Float) throws {
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: tint
        )
        
        try setWhiteBalanceGains(videoDevice.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    func changeWhiteBalance(temperature: Float) throws {
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: tint
        )
        
        try setWhiteBalanceGains(videoDevice.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    func changeWhiteBalance(tint: Float, temperature: Float) throws {
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: tint
        )
        
        try setWhiteBalanceGains(videoDevice.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    private func setup() {
        let iso: Float = min(1729, maxISO)
        let duration: Float = min(0.6, maxShutterSpeed)
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: min(5400, maxTemperature),
            tint: min(0, maxTint)
        )
        let gains = videoDevice.deviceWhiteBalanceGains(for: temperatureAndTint)
        let normalizedGains = self.normalizedGains(gains)

        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .custom
            videoDevice.whiteBalanceMode = .locked
            videoDevice.setExposureModeCustom(
                duration: exposureDuration(duration),
                iso: iso
            )
            videoDevice.setWhiteBalanceModeLocked(
                with: normalizedGains,
                completionHandler: nil
            )
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.defaultISO = iso
            self.defaultShutterSpeed = duration
            self.defaultTint = self.tint
            self.defaultTemperature = self.temperature
            self.isInitialized = true
            self.delegate?.sessionDidStart()
        }
    }
    
    private func setWhiteBalanceGains(_ gains: AVCaptureDevice.WhiteBalanceGains) throws {
        try self.videoDevice!.lockForConfiguration()
        let normalizedGains = self.normalizedGains(gains) // Conversion can yield out-of-bound values, cap to limits
        self.videoDevice!.setWhiteBalanceModeLocked(with: normalizedGains, completionHandler: nil)
        self.videoDevice!.unlockForConfiguration()
    }
    
    private func normalizedGains(_ gains: AVCaptureDevice.WhiteBalanceGains) -> AVCaptureDevice.WhiteBalanceGains {
        var g = gains
        
        g.redGain = max(1.0, g.redGain)
        g.greenGain = max(1.0, g.greenGain)
        g.blueGain = max(1.0, g.blueGain)
        
        g.redGain = min(videoDevice.maxWhiteBalanceGain, g.redGain)
        g.greenGain = min(videoDevice.maxWhiteBalanceGain, g.greenGain)
        g.blueGain = min(videoDevice.maxWhiteBalanceGain, g.blueGain)
        
        return g
    }

    private func exposureDuration(_ duration: Float) -> CMTime {
        let p = pow(Double(duration), kExposureDurationPower) // Apply power function to expand slider's low-end range
        let minDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
        return CMTimeMakeWithSeconds(newDurationSeconds, preferredTimescale: 1000 * 1000 * 1000)
    }
    
    func setCustomExposure(speed: Float, iso: Float) {
        guard let cameraDevice = videoDevice else { return }
        
        let ev = ExposureValue(aperture: aperture, speed: speed, iso: iso)
        
        var safeSpeed = min(max(speed, Float(CMTimeGetSeconds(cameraDevice.activeFormat.minExposureDuration))), 1/15.0)
        var safeISO = ev.iso(withAperture: aperture, speed: safeSpeed)
        if safeISO < cameraDevice.activeFormat.minISO || safeISO > cameraDevice.activeFormat.maxISO {
            safeISO = min(max(safeISO, cameraDevice.activeFormat.minISO), cameraDevice.activeFormat.maxISO)
            safeSpeed = min(max(ev.speed(withAperture: aperture, iso: safeISO), Float(CMTimeGetSeconds(cameraDevice.activeFormat.minExposureDuration))), Float(CMTimeGetSeconds(cameraDevice.activeFormat.maxExposureDuration)))
        }
        var duration = CMTimeMakeWithSeconds(Double(safeSpeed), preferredTimescale: 1000000000)
        if duration < cameraDevice.activeFormat.minExposureDuration {
            duration = cameraDevice.activeFormat.minExposureDuration
        }
        if duration > cameraDevice.activeFormat.maxExposureDuration {
            duration = cameraDevice.activeFormat.maxExposureDuration
        }
        do {
            try cameraDevice.lockForConfiguration()
            cameraDevice.exposureMode = .custom
            cameraDevice.setExposureModeCustom(
                duration: duration,
                iso: safeISO,
                completionHandler: nil
            )
            cameraDevice.unlockForConfiguration()
        } catch {
        }
    }
    
    func clearCustomExposure() {
        guard let cameraDevice = videoDevice, cameraDevice.exposureMode != .continuousAutoExposure else { return }
        do {
            try cameraDevice.lockForConfiguration()
            cameraDevice.exposureMode = .continuousAutoExposure
            cameraDevice.unlockForConfiguration()
        } catch {
        }
    }
}

extension CameraSDK: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                debugPrint("unable to get image from sample buffer")
                return
            }
            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
            let image = self.convert(cmage: ciimage)
            let luminosity = Int(image.luminosity)
            Task {
                let distance = await self.measure.eyesDistance(in: imageBuffer)
                let faceDistance = self.settings.referalFaceDistance
                let eyesDistance = self.settings.referalEyesDistance
                let resultDistance: Float? = Float(eyesDistance) / distance * Float(faceDistance)
                await MainActor.run {
                    guard let result = resultDistance,
                        result > 0,
                        result != .infinity else {
                        self.delegate?.updateDistance(0)
                        self.distances = []
                        return
                    }
                    self.distances.append(Int(ceil(result)))
                    if self.distances.count >= 3 {
                        self.delegate?.updateDistance(currentDistance)
                        self.distances = []
                    }
                    self.delegate?.updateLuminosity(luminosity)
                }
            }
    }
    
    private func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let width = cgImage.width
        
        let y = Int(80 * UIScreen.main.nativeScale)
        let ovalWidth = Int(185 * UIScreen.main.nativeScale)
        let ovalheight = Int(265 * UIScreen.main.nativeScale)
        let cropRect = CGRect(x: width / 2 - ovalWidth / 2, y: y, width: ovalWidth, height: ovalheight)
        let croppedImage = cgImage.cropping(to: cropRect) ?? cgImage
        let image = UIImage(cgImage: croppedImage)
        return image.ellipseMasked
    }
}

fileprivate extension UIImage {
    var ellipseMasked: UIImage {
        let rect = CGRect(origin: .zero, size: size)
        let format = imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIBezierPath(ovalIn: rect).addClip()
            draw(in: rect)
        }
    }
}
