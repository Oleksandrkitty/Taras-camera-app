//
//  CameraSDK.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 07.06.2021.
//

import Foundation
import AVKit

protocol CameraSDKDelegate: AnyObject {
    func sessionDidStart()
}

class CameraSDK {
    private enum Setting {
        case iso, exposure, shutterSpeed, whiteBalance, usv, none
    }
    
    private let kExposureDurationPower = 5.0 // Higher numbers will give the slider more sensitivity at shorter durations
    private let kExposureMinimumDuration = 1.0 / 1000 // Limit exposure duration to a useful range
    
    private let router: CameraRouting
    let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice!
    let captureSession: AVCaptureSession = AVCaptureSession()
    
    var minISO: Float {
        return videoDevice.activeFormat.minISO
    }
    
    var maxISO: Float {
        return videoDevice.activeFormat.maxISO
    }
    
    var iso: Float {
        return videoDevice.iso
    }
    
    var minExposureTargetBias: Float {
        return videoDevice.minExposureTargetBias
    }
    
    var maxExposureTargetBias: Float {
        return videoDevice.maxExposureTargetBias
    }
    
    var exposureTargetBias: Float {
        return videoDevice.exposureTargetBias
    }
    
    var minShutterSpeed: Float {
        return 0.0
    }
    
    var maxShutterSpeed: Float {
        return 0.7
    }
    
    var shutterSpeed: Float {
        let exposureDurationSeconds = CMTimeGetSeconds(videoDevice.exposureDuration)
        let minExposureDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxExposureDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        // Map from duration to non-linear UI range 0-1
        let p = (exposureDurationSeconds - minExposureDurationSeconds) / (maxExposureDurationSeconds - minExposureDurationSeconds) // Scale to 0-1
        return Float(pow(p, 1 / kExposureDurationPower))
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
    
    func requestCameraAccess() {
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
        captureSession.commitConfiguration()
        captureSession.startRunning()
        delegate?.sessionDidStart()
    }
    
    func changeISO(_ value: Float) throws {
        try videoDevice.lockForConfiguration()
        videoDevice.setExposureModeCustom(
            duration: AVCaptureDevice.currentExposureDuration,
            iso: value
        )
        videoDevice.unlockForConfiguration()
    }
    
    func changeShutterSpeed(_ value: Float) throws {
        let p = pow(Double(value), kExposureDurationPower) // Apply power function to expand slider's low-end range
        let minDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
        let duration = CMTimeMakeWithSeconds(newDurationSeconds, preferredTimescale: 1000 * 1000 * 1000)
        try videoDevice!.lockForConfiguration()
        videoDevice.setExposureModeCustom(
            duration: duration,
            iso: AVCaptureDevice.currentISO
        )
        videoDevice.unlockForConfiguration()
    }
    
    func changeExposure(duration: Float, iso: Float) throws {
        let p = pow(Double(duration), kExposureDurationPower) // Apply power function to expand slider's low-end range
        let minDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
        let duration = CMTimeMakeWithSeconds(newDurationSeconds, preferredTimescale: 1000 * 1000 * 1000)
        try videoDevice!.lockForConfiguration()
        videoDevice.setExposureModeCustom(
            duration: duration,
            iso: iso
        )
        videoDevice.unlockForConfiguration()
    }
    
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
        
        try setWhiteBalanceGains(self.videoDevice!.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    func changeWhiteBalance(temperature: Float) throws {
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: tint
        )
        
        try setWhiteBalanceGains(self.videoDevice!.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    func changeWhiteBalance(tint: Float, temperature: Float) throws {
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: tint
        )
        
        try setWhiteBalanceGains(self.videoDevice!.deviceWhiteBalanceGains(for: temperatureAndTint))
    }
    
    func setupISO() {
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .custom
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func setupExposure() {
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .continuousAutoExposure
            videoDevice.activeVideoMaxFrameDuration = CMTime.invalid
            videoDevice.activeVideoMinFrameDuration = CMTime.invalid
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func setupShutterSpeed() {
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .custom
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func setupWhiteBalance() {
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.whiteBalanceMode = .locked
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
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
        
        g.redGain = min(self.videoDevice!.maxWhiteBalanceGain, g.redGain)
        g.greenGain = min(self.videoDevice!.maxWhiteBalanceGain, g.greenGain)
        g.blueGain = min(self.videoDevice!.maxWhiteBalanceGain, g.blueGain)
        
        return g
    }
}
