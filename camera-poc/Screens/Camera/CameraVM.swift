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
    enum LightMode {
        case normal
        case darkRoom
    }
    
    private enum Setting {
        case iso, exposure, whiteBalance, usv, none
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
    private(set) var isSingleShootEnabled: Bound<Bool> = Bound(false)
    private(set) var isDarkModeEnabled: Bound<Bool> = Bound(false)
    
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
    private(set) var wbValue: Bound<String> = Bound("0.0")
    private(set) var usvValue: Bound<String> = Bound("Low")
    private(set) var usvPercents: Bound<String> = Bound("0%")
    private(set) lazy var frameSize: Bound<FrameSize> = Bound(.none)
    
    private var defaultSeries: BrigtnessSeries!
    private var series: BrigtnessSeries = Medium {
        didSet {
            brightness = series.min / 100
            minBrightness = series.min / 100
            maxBrightness = series.max / 100
            UIScreen.main.brightness = 1.0
        }
    }

    private var minBrightness: CGFloat = 0.0
    private var maxBrightness: CGFloat = 1.0
    private var brightness: CGFloat = 0.0 {
        didSet {
            self.usvPercents.value = "\(Int(brightness * 100))%"
        }
    }
    private var currentSetting: Setting = .none
    private var photosCount = 0
    
    //Use these values as current state when change from Dark mode to Normal
    private var lightMode: LightMode = .normal
    private var currentISO: Float = 0.0
    private var currentShutterSpeed: Float = 0.0
    
    //Detect volume button up/down to start capture
    private var outputVolumeObserve: NSKeyValueObservation?
    private let audioSession = AVAudioSession.sharedInstance()
    
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
        UIScreen.main.brightness = 1.0
        self.sdk.delegate = self
        usvPercents.value = "\(Int(brightness * 100))%"
        frameSize.value = FramingService.size()
        listenVolumeButton()
    }
    
    func requestCameraAccess() {
        guard !sdk.isInitialized else {
            return
        }
        sdk.requestCameraAccess()
    }
    
    func capture() {
        guard sdk.isInitialized else {
            return
        }
        guard isCaptureEnabled.value else {
            return
        }
        //Set Normal light state before making photos
        if isDarkModeEnabled.value {
            do {
                try sdk.changeExposure(duration: currentShutterSpeed, iso: currentISO)
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        self.isCaptureEnabled.value = false
        photosCount = 0
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
        let delay = isDarkModeEnabled.value ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sliderMinValue.value = self.sdk.minISO
            self.sliderMaxValue.value = self.sdk.maxISO
            self.sliderCurrentValue.value = self.sdk.iso
        }
        setDarkModeEnabled(false)
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
        let delay = isDarkModeEnabled.value ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sliderMinValue.value = self.sdk.minShutterSpeed
            self.sliderMaxValue.value = self.sdk.maxShutterSpeed
            self.sliderCurrentValue.value = self.sdk.shutterSpeed
        }
        setDarkModeEnabled(false)
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
        guard sdk.isInitialized else { return }
        setDarkModeEnabled(false)
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
        guard sdk.isInitialized else { return }
        do {
            try sdk.changeWhiteBalance(tint: tint)
            tintLabel.value = "\(Int(tint))"
        } catch {
            assertionFailure("Could not lock device for white balance configuration: \(error)")
        }
    }
    
    func change(temperature: Float) {
        guard sdk.isInitialized else { return }
        do {
            try sdk.changeWhiteBalance(temperature: temperature)
            temperatureLabel.value = "\(Int(temperature))"
        } catch {
            assertionFailure("Could not lock device for white balance configuration: \(error)")
        }
    }
    
    func change(brightness: Float) {
        self.brightness = CGFloat(brightness) / 100
    }
    
    func changeLight() {
        isUSVPickerEnabled.value = false
        isSliderEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        currentSetting = .none
        router.presentChangeLight(from: Float(series.min), to: Float(series.max))
    }
    
    func setSingleShootEnabled(_ isEnabled: Bool) {
        isSingleShootEnabled.value = isEnabled
        brightness = minBrightness
    }
    
    func setDarkModeEnabled(_ isEnabled: Bool) {
        guard isDarkModeEnabled.value != isEnabled else {
            return
        }
        isDarkModeEnabled.value = isEnabled
        if isEnabled {
            isUSVPickerEnabled.value = false
            isWhiteBalanceSliderEnabled.value = false
            isSliderEnabled.value = false
            currentSetting = .none
            setupDarkRoomMode()
        } else {
            setupNormalLightMode()
        }
    }
    
    func setupNormalLightMode() {
        guard lightMode != .normal else {
            return
        }
        do {
            try sdk.changeExposure(duration: currentShutterSpeed, iso: currentISO)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        lightMode = .normal
    }
    
    func setupDarkRoomMode() {
        guard lightMode != .darkRoom else {
            return
        }
        do {
            currentISO = sdk.iso
            currentShutterSpeed = sdk.shutterSpeed
            try sdk.changeExposure(duration: sdk.maxShutterSpeed, iso: sdk.maxISO)
        } catch {
            assertionFailure(error.localizedDescription)
        }
        lightMode = .darkRoom
    }
    
    func presentFamilyDevicePicker() {
        router.presentFamilyDevicePicker()
    }
    
    func change(size: FrameSize) {
        frameSize.value = size
        FramingService.set(size: size)
    }
    
    func reset() {
        guard sdk.isInitialized else {
            return
        }
        currentSetting = .none
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = false
        isSingleShootEnabled.value = false
        do {
            try sdk.changeExposure(duration: sdk.defaultShutterSpeed, iso: sdk.defaultISO)
            try sdk.changeWhiteBalance(tint: sdk.defaultTint, temperature: sdk.defaultTemperature)
            change(series: defaultSeries)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateUI()
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    private func makePhoto() {
        if self.brightness > self.maxBrightness || (self.isSingleShootEnabled.value && self.photosCount == 1) {
            //To make sure last photo was saved to photo library
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //Set it back to Dark-room mode if needed
                if self.isDarkModeEnabled.value {
                    do {
                        try self.sdk.changeExposure(duration: self.sdk.maxShutterSpeed, iso: self.sdk.maxISO)
                    } catch {
                        assertionFailure(error.localizedDescription)
                    }
                }
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
            var settings: AVCapturePhotoSettings
            if let uncompressedPixelType = self.sdk.photoOutput.supportedPhotoPixelFormatTypes(for: .tif).first {
                settings = AVCapturePhotoSettings(format: [
                    kCVPixelBufferPixelFormatTypeKey as String : uncompressedPixelType
                ])
            } else if let uncompressedPixelType = self.sdk.photoOutput.supportedPhotoPixelFormatTypes(for: .dng).first {
                settings = AVCapturePhotoSettings(format: [
                    kCVPixelBufferPixelFormatTypeKey as String : uncompressedPixelType
                ])
            } else {
                settings = AVCapturePhotoSettings()
            }
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

    func listenVolumeButton() {
        do {
            try audioSession.setActive(true)
        } catch {
            assertionFailure(error.localizedDescription)
        }

        outputVolumeObserve = audioSession.observe(\.outputVolume) { [weak self] (audioSession, changes) in
            self?.capture()
        }
    }
}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.isFlashEnabled.value = false
        UIScreen.main.brightness = 1.0
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                let fileName = "\(UIDevice.modelName)_\(self.dateFormatter.string(from: Date()))_ISO: \("A \(Int(self.sdk.iso))")_Exp: \(String(format: "%0.2f", self.sdk.shutterSpeed))_Tint: \(Int(self.sdk.tint))_Temperature: \(Int(self.sdk.temperature))_Frame: \(self.series.title)_Light: \(Int(self.brightness * 100))%"
                options.originalFilename = fileName
                if let data = photo.fileDataRepresentation() {
                    creationRequest.addResource(with: .photo, data: data, options: options)
                }
                if !self.isSingleShootEnabled.value {
                    let brightness = self.brightness + self.series.step
                    self.brightness = round(brightness * 100) / 100
                }
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
        defaultSeries = series
        updateUI()
    }
    
    private func updateUI() {
        self.isoValue.value = "A \(Int(sdk.iso))"
        self.exposureValue.value = String(format: "%0.2f", sdk.shutterSpeed)
        self.wbValue.value = "AWB"
        self.usvValue.value = series.title
        self.tintLabel.value = "\(Int(sdk.tint))"
        self.temperatureLabel.value = "\(Int(sdk.temperature))"
    }
}
