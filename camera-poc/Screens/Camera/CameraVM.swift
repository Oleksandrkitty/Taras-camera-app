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
    private let router: CameraRouting
    private let sdk: CameraSDK
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        return dateFormatter
    }()
    
    private var screenBrightness: CGFloat = 0.5
    private(set) var isFlashEnabled: Bound<Bool> = Bound(false)
    private(set) var isUSVPickerEnabled: Bound<Bool> = Bound(false)
    private(set) var isSliderEnabled: Bound<Bool> = Bound(false)
    private(set) var isWhiteBalanceSliderEnabled: Bound<Bool> = Bound(false)
    private(set) var isCaptureEnabled: Bound<Bool> = Bound(true)
    
    private(set) var flashBrightness: Bound<CGFloat> = Bound(0.0)
    private(set) var sliderMinValue: Bound<Float> = Bound(0.0)
    private(set) var sliderMaxValue: Bound<Float> = Bound(0.0)
    private(set) var sliderCurrentValue: Bound<Float> = Bound(0.0)
    
    private(set) var tintMinValue: Bound<Float> = Bound(0.0)
    private(set) var tintMaxValue: Bound<Float> = Bound(0.0)
    private(set) var tintValue: Bound<Float> = Bound(0.0)
    private(set) var tintLabel: Bound<String> = Bound("")
    
    private(set) var temperatureMinValue: Bound<Float> = Bound(0.0)
    private(set) var temperatureMaxValue: Bound<Float> = Bound(0.0)
    private(set) var temperatureValue: Bound<Float> = Bound(0.0)
    private(set) var temperatureLabel: Bound<String> = Bound("")
    
    private(set) var isoValue: Bound<String> = Bound("A 100")
    private(set) var exposureValue: Bound<String> = Bound("0.0")
    private(set) var shutterSpeedValue: Bound<String> = Bound("0.0")
    private(set) var wbValue: Bound<String> = Bound("0.0")
    private(set) var usvValue: Bound<String> = Bound("Low")
    private(set) var usvPercents: Bound<String> = Bound("0%")
    
    private var defaultISO: Float!
    private var defaultExposure: Float!
    private var defaultShutterSpeed: Float!
    private var defaultTint: Float!
    private var defaultTemperature: Float!
    private var defaultSeries: BrigtnessSeries!
    
    private var series: BrigtnessSeries = Medium {
        didSet {
            brightness = series.min / 100
            minBrightness = series.min / 100
            maxBrightness = series.max / 100
            UIScreen.main.brightness = minBrightness
        }
    }

    private var currentSetting: Setting = .none
    private var brightness: CGFloat = 0.0 {
        didSet {
            self.usvPercents.value = "\(Int(brightness * 100))%"
        }
    }
    private var minBrightness: CGFloat = 0.0
    private var maxBrightness: CGFloat = 1.0
    
    private var photosCount = 0
    
    var session: AVCaptureSession {
        return sdk.captureSession
    }
    
    init(router: CameraRouting) {
        self.router = router
        self.sdk = CameraSDK(router: router)
        super.init()
        brightness = series.min / 100
        minBrightness = series.min / 100
        maxBrightness = series.max / 100
        UIScreen.main.brightness = minBrightness
        self.sdk.delegate = self
        usvPercents.value = "\(Int(brightness * 100))%"
    }
    
    func requestCameraAccess() {
        sdk.requestCameraAccess()
    }
    
    func capture() {
        self.isCaptureEnabled.value = false
        photosCount = 0
        brightness = minBrightness
        makePhoto()
    }

    func selectISO() {
        guard currentSetting != .iso else {
            isSliderEnabled.value = false
            currentSetting = .none
            return
        }
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
            isSliderEnabled.value = false
            currentSetting = .none
            return
        }
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = true
        currentSetting = .exposure
        
        sliderMinValue.value = sdk.minShutterSpeed
        sliderMaxValue.value = sdk.maxShutterSpeed
        sliderCurrentValue.value = sdk.shutterSpeed
    }
    
    func selectShutterSpeed() {
        guard currentSetting != .shutterSpeed else {
            isSliderEnabled.value = false
            currentSetting = .none
            return
        }
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
            isWhiteBalanceSliderEnabled.value = false
            currentSetting = .none
            return
        }
        isUSVPickerEnabled.value = false
        isSliderEnabled.value = false
        isWhiteBalanceSliderEnabled.value = true
        currentSetting = .whiteBalance
        
        tintMinValue.value = sdk.minTint
        tintMaxValue.value = sdk.maxTint
        tintValue.value = sdk.tint
        
        temperatureMinValue.value = sdk.minTemperature
        temperatureMaxValue.value = sdk.maxTemperature
        temperatureValue.value = sdk.temperature
    }
    
    func selectUSV() {
        guard currentSetting != .usv else {
            isUSVPickerEnabled.value = false
            currentSetting = .none
            return
        }
        currentSetting = .usv
        isSliderEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isUSVPickerEnabled.value = true
    }
    
    func change(value: Float) {
        do {
            switch currentSetting {
                case .iso:
                    try sdk.changeExposure(duration: sdk.shutterSpeed, iso: value)
                    self.isoValue.value = "A \(Int(sdk.iso))"
                case .exposure:
                    try sdk.changeExposure(duration: value, iso: sdk.iso)
                    self.exposureValue.value = String(format: "%0.2f", sdk.shutterSpeed)
                default: break
            }
        } catch {
            assertionFailure("Could not lock device for configuration: \(error)")
        }
    }
    
    func change(series: BrigtnessSeries) {
        self.series = series
        self.usvValue.value = series.title
        self.isUSVPickerEnabled.value = false
        self.currentSetting = .none
    }
    
    func change(tint: Float) {
        do {
            try sdk.changeWhiteBalance(tint: tint)
            tintLabel.value = "\(Int(tint))"
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func change(temperature: Float) {
        do {
            try sdk.changeWhiteBalance(temperature: temperature)
            temperatureLabel.value = "\(Int(temperature))"
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func reset() {
        currentSetting = .none
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = false
        do {
            try sdk.changeExposure(duration: defaultShutterSpeed, iso: defaultISO)
            try sdk.changeWhiteBalance(tint: defaultTint, temperature: defaultTemperature)
            change(series: defaultSeries)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateUI()
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    private func makePhoto() {
        
        if self.brightness > self.maxBrightness {
            //To make sure last photo was saved to photo library
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isCaptureEnabled.value = true
                self.brightness = self.minBrightness
                self.router.presentPhotosList(maxCount: self.photosCount)
            }
            return
        }
        self.photosCount += 1
        self.capture(brightness: self.brightness)
    }
    
    private func capture(brightness: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            //set starting brightness to achive flashing effect
            UIScreen.main.brightness = max(brightness - 0.12, self.series.min / 100)
            self.screenBrightness = max(brightness - 0.12, self.series.min / 100)
            self.isFlashEnabled.value = true
            UIScreen.main.brightness = brightness
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sdk.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.isFlashEnabled.value = false
        UIScreen.main.brightness = self.screenBrightness
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                let fileName = "\(UIDevice.modelName)_\(self.dateFormatter.string(from: Date()))_ISO: \("A \(Int(self.sdk.iso))")_Exp: \(String(format: "%0.2f", self.sdk.shutterSpeed))_Tint: \(Int(self.sdk.tint))_Temperature: \(Int(self.sdk.temperature))_USV: \(Int(self.series.max))%_Step: \(Int(self.brightness * 100))%.jpg"
                options.originalFilename = fileName
                if let data = photo.fileDataRepresentation() {
                    creationRequest.addResource(with: .photo, data: data, options: options)
                }
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

extension CameraVM: CameraSDKDelegate {
    func sessionDidStart() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sdk.setupISO()
            self.sdk.setupWhiteBalance()
            do {
                try self.sdk.changeExposure(duration: self.sdk.maxShutterSpeed / 2, iso: self.sdk.iso)
            } catch {
                assertionFailure(error.localizedDescription)
            }
            
            self.defaultISO = self.sdk.iso
            self.defaultExposure = self.sdk.exposureTargetBias
            self.defaultShutterSpeed = self.sdk.maxShutterSpeed / 2
            self.defaultTint = self.sdk.tint
            self.defaultTemperature = self.sdk.temperature
            self.defaultSeries = self.series
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateUI()
            }
        }
    }
    
    private func updateUI() {
        self.isoValue.value = "A \(Int(sdk.iso))"
        self.exposureValue.value = String(format: "%0.2f", sdk.shutterSpeed)
        self.shutterSpeedValue.value = "\(sdk.shutterSpeed)"
        self.wbValue.value = "AWB"
        self.usvValue.value = series.title
        self.tintLabel.value = "\(Int(sdk.tint))"
        self.temperatureLabel.value = "\(Int(sdk.temperature))"
    }
}
