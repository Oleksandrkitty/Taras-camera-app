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
    private let sdk: CameraSDK
    
    private var screenBrightness: CGFloat = 0.5
    private(set) var isFlashEnabled: Bound<Bool> = Bound(false)
    private(set) var isUSVPickerEnabled: Bound<Bool> = Bound(false)
    private(set) var isSliderEnabled: Bound<Bool> = Bound(false)
    private(set) var isWhiteBalanceSliderEnabled: Bound<Bool> = Bound(false)
    
    private(set) var flashBrightness: Bound<CGFloat> = Bound(0.0)
    private(set) var sliderMinValue: Bound<Float> = Bound(0.0)
    private(set) var sliderMaxValue: Bound<Float> = Bound(0.0)
    private(set) var sliderCurrentValue: Bound<Float> = Bound(0.0)
    
    private(set) var tintMinValue: Bound<Float> = Bound(0.0)
    private(set) var tintMaxValue: Bound<Float> = Bound(0.0)
    private(set) var tintValue: Bound<Float> = Bound(0.0)
    
    private(set) var temperatureMinValue: Bound<Float> = Bound(0.0)
    private(set) var temperatureMaxValue: Bound<Float> = Bound(0.0)
    private(set) var temperatureValue: Bound<Float> = Bound(0.0)
    
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
    
    var session: AVCaptureSession {
        return sdk.captureSession
    }
    
    init(router: CameraRouting) {
        self.sdk = CameraSDK(router: router)
        super.init()
        brightness = series.min / 100
        minBrightness = series.min / 100
        maxBrightness = series.max / 100
        seriesString.value = "\(series.min)% - \(series.max)%"
        UIScreen.main.brightness = minBrightness
    }
    
    func requestCameraAccess() {
        sdk.requestCameraAccess()
    }
    
    func capture() {
        brightness = minBrightness
        makePhoto()
    }

    func selectISO() {
        guard currentSetting != .iso else {
            return
        }
        sdk.setupISO()
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = true
        currentSetting = .iso
        sliderMinValue.value = sdk.minISO
        sliderMaxValue.value = sdk.maxISO
        sliderCurrentValue.value = sdk.iso
    }
    
    func selectExposure() {
        guard currentSetting != .exposure else {
            return
        }
        sdk.setupExposure()
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = true
        currentSetting = .exposure
        sliderMinValue.value = sdk.minExposureTargetBias
        sliderMaxValue.value = sdk.maxExposureTargetBias
        sliderCurrentValue.value = sdk.exposureTargetBias
    }
    
    func selectShutterSpeed() {
        guard currentSetting != .shutterSpeed else {
            return
        }
        sdk.setupShutterSpeed()
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = true
        currentSetting = .shutterSpeed
        sliderMinValue.value = sdk.minShutterSpeed
        sliderMaxValue.value = sdk.maxShutterSpeed
        sliderCurrentValue.value = sdk.shutterSpeed
    }
    
    func selectWhiteBalance() {
        guard currentSetting != .whiteBalance else {
            return
        }
        sdk.setupWhiteBalance()
        isUSVPickerEnabled.value = false
        isSliderEnabled.value = false
        isWhiteBalanceSliderEnabled.value = true
        
        tintMinValue.value = sdk.minTint
        tintMaxValue.value = sdk.maxTint
        tintValue.value = sdk.tint
        
        temperatureMinValue.value = sdk.minTemperature
        temperatureMaxValue.value = sdk.maxTemperature
        temperatureValue.value = sdk.temperature
    }
    
    func selectUSV() {
        guard currentSetting != .usv else {
            return
        }
        isSliderEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isUSVPickerEnabled.value = true
    }
    
    func change(value: Float) {
        do {
            switch currentSetting {
                case .iso: try sdk.changeISO(value)
                case .exposure: try sdk.changeExposure(value)
                case .shutterSpeed: try sdk.changeShutterSpeed(value)
                default: break
            }
        } catch {
            assertionFailure("Could not lock device for configuration: \(error)")
        }
    }
    
    func change(series: BrigtnessSeries) {
        self.series = series
    }
    
    func change(tint: Float) {
        sdk.changeWhiteBalance(tint: tint)
    }
    
    func change(temperature: Float) {
        sdk.changeWhiteBalance(temperature: temperature)
    }
    
    private func makePhoto() {
        if brightness > maxBrightness {
            return
        }
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
                    self.sdk.photoOutput.capturePhoto(with: settings, delegate: self)
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
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
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
