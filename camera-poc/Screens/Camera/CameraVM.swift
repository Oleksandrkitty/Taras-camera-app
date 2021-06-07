//
//  CameraVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import Foundation
import AVKit
import Photos

class CameraVM: NSObject {
    private enum Setting {
        case iso, exposure, shutterSpeed, whiteBalance, usv, none
    }
    
    private let kExposureDurationPower = 5.0 // Higher numbers will give the slider more sensitivity at shorter durations
    private let kExposureMinimumDuration = 1.0/1000 // Limit exposure duration to a useful range
    
    private let router: CameraRouting
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    private var videoDevice: AVCaptureDevice!
    let captureSession: AVCaptureSession = AVCaptureSession()
    
    private var screenBrightness: CGFloat = 0.5
    private(set) var isFlashEnabled: Bound<Bool> = Bound(false)
    private(set) var isUSVPickerEnabled: Bound<Bool> = Bound(false)
    private(set) var isSliderEnabled: Bound<Bool> = Bound(false)
    
    private(set) var flashBrightness: Bound<CGFloat> = Bound(0.0)
    private(set) var sliderMinValue: Bound<Float> = Bound(0.0)
    private(set) var sliderMaxValue: Bound<Float> = Bound(0.0)
    private(set) var sliderCurrentValue: Bound<Float> = Bound(0.0)
    
    private(set) var seriesString: Bound<String> = Bound("")
    private var series: BrigtnessSeries = Medium {
        didSet {
            brightness = series.min / 100
            minBrightness = series.min / 100
            maxBrightness = series.max / 100
            seriesString.value = "\(series.min)% - \(series.max)%"
            UIScreen.main.brightness = minBrightness
        }
    }

    private var currentSetting: Setting = .none
    private var brightness: CGFloat = 0.0
    private var minBrightness: CGFloat = 0.0
    private var maxBrightness: CGFloat = 1.0
    
    init(router: CameraRouting) {
        self.router = router
        super.init()
        brightness = series.min / 100
        minBrightness = series.min / 100
        maxBrightness = series.max / 100
        seriesString.value = "\(series.min)% - \(series.max)%"
        UIScreen.main.brightness = minBrightness
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
    }
    
    func capture() {
        brightness = minBrightness
        makePhoto()
    }

    func selectISO() {
        guard currentSetting != .iso else {
            return
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .custom
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        isSliderEnabled.value = true
        isUSVPickerEnabled.value = false
        currentSetting = .iso
        sliderMinValue.value = videoDevice.activeFormat.minISO
        sliderMaxValue.value = videoDevice.activeFormat.maxISO
        sliderCurrentValue.value = videoDevice.iso
    }
    
    func selectExposure() {
        guard currentSetting != .exposure else {
            return
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .continuousAutoExposure
            videoDevice.activeVideoMaxFrameDuration = CMTime.invalid
            videoDevice.activeVideoMinFrameDuration = CMTime.invalid
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        isSliderEnabled.value = true
        isUSVPickerEnabled.value = false
        currentSetting = .exposure
        sliderMinValue.value = videoDevice.minExposureTargetBias
        sliderMaxValue.value = videoDevice.maxExposureTargetBias
        sliderCurrentValue.value = videoDevice.exposureTargetBias
    }
    
    func selectShutterSpeed() {
        guard currentSetting != .shutterSpeed else {
            return
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .custom
            videoDevice.unlockForConfiguration()
        } catch {
            assertionFailure(error.localizedDescription)
        }
        isSliderEnabled.value = true
        isUSVPickerEnabled.value = false
        currentSetting = .shutterSpeed
        sliderMinValue.value = 0
        sliderMaxValue.value = 1
        let exposureDurationSeconds = CMTimeGetSeconds(videoDevice.exposureDuration)
        let minExposureDurationSeconds = max(CMTimeGetSeconds(videoDevice.activeFormat.minExposureDuration), kExposureMinimumDuration)
        let maxExposureDurationSeconds = CMTimeGetSeconds(videoDevice.activeFormat.maxExposureDuration)
        // Map from duration to non-linear UI range 0-1
        let p = (exposureDurationSeconds - minExposureDurationSeconds) / (maxExposureDurationSeconds - minExposureDurationSeconds) // Scale to 0-1
        sliderCurrentValue.value = Float(pow(p, 1 / kExposureDurationPower)) // Apply inverse power
    }
    
    func selectWhiteBalance() {
        guard currentSetting != .whiteBalance else {
            return
        }
        isSliderEnabled.value = true
        isUSVPickerEnabled.value = false
    }
    
    func selectUSV() {
        guard currentSetting != .usv else {
            return
        }
        isSliderEnabled.value = false
        isUSVPickerEnabled.value = true
    }
    
    func change(value: Float) {
        print(value)
        do {
            switch currentSetting {
            case .iso: try changeISO(value)
            case .exposure: try changeExposure(value)
            case .shutterSpeed: try changeShutterSpeed(value)
            default: break
            }
        } catch {
            assertionFailure("Could not lock device for configuration: \(error)")
        }
    }
    
    func change(series: BrigtnessSeries) {
        self.series = series
    }
    
    private func changeISO(_ value: Float) throws {
        try videoDevice.lockForConfiguration()
        videoDevice.setExposureModeCustom(
            duration: AVCaptureDevice.currentExposureDuration,
            iso: value
        )
        videoDevice.unlockForConfiguration()
    }
    
    private func changeShutterSpeed(_ value: Float) throws {
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
    
    private func changeExposure(_ value: Float) throws {
        try videoDevice.lockForConfiguration()
        videoDevice.setExposureTargetBias(value)
        videoDevice.unlockForConfiguration()
    }
    
    private func makePhoto() {
        if brightness > maxBrightness {
            return
        }
        print("brightness \(brightness)")
        capture(brightness: brightness)
    }
    
    private func capture(brightness: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            //set starting brightness to achive flashing effect
            UIScreen.main.brightness = max(brightness - 0.12, self.series.min / 100)
            self.screenBrightness = max(brightness - 0.12, self.series.min / 100)
            self.isFlashEnabled.value = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIScreen.main.brightness = brightness
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.photoOutput.capturePhoto(with: settings, delegate: self)
                }
            }
        }
    }
}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.isFlashEnabled.value = false
            UIScreen.main.brightness = self.screenBrightness
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
//                let creationRequest = PHAssetCreationRequest.forAsset()
//                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
                let brightness = self.brightness + self.series.step
                self.brightness = round(brightness * 100) / 100
                self.makePhoto()
            } completionHandler: { isSaved, error in
                guard let error = error else { return }
                assertionFailure("Handle saving error: \(error.localizedDescription)")
            }
        }
    }
}

struct BrigtnessSeries {
    let min: CGFloat
    let max: CGFloat
    let step: CGFloat
}

let Low = BrigtnessSeries(min: 10, max: 40, step: 0.05)
let Medium = BrigtnessSeries(min: 45, max: 70, step: 0.05)
let High = BrigtnessSeries(min: 75, max: 100, step: 0.05)
