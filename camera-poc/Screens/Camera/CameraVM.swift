//
//  CameraVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import Foundation
import AVKit
import Photos
import Combine

class CameraVM: NSObject {
    enum LightMode {
        case normal
        case darkRoom
    }
    
    private enum Setting {
        case iso, exposure, aperture, whiteBalance, usv, none
    }
    private let router: CameraRouting
    private let sdk: CameraSDK
    
    private var isoCancellabel: AnyObject?
    private var exposureCancellabel: AnyObject?
    private var apertureCancellabel: AnyObject?
    private var screenBrightness: CGFloat = 0.5
    private var captureFormat: CaptureFormat = .tiff
    private(set) var isFlashEnabled: Bound<Bool> = Bound(false)
    private(set) var isUSVPickerEnabled: Bound<Bool> = Bound(false)
    private(set) var isSliderEnabled: Bound<Bool> = Bound(false)
    private(set) var isWhiteBalanceSliderEnabled: Bound<Bool> = Bound(false)
    private(set) var isCaptureEnabled: Bound<Bool> = Bound(true)
    private(set) var isSingleShootEnabled: Bound<Bool> = Bound(false)
    private(set) var isDarkModeEnabled: Bound<Bool> = Bound(false)
    var isCaptureFormatSelectionEnabled: Bool {
        if #available(iOS 14.3, *) {
            return true
        }
        return false
    }
    
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
    private(set) var apertureValue: Bound<String> = Bound("0.0")
    private(set) var wbValue: Bound<String> = Bound("0.0")
    private(set) var usvValue: Bound<String> = Bound("Low")
    private(set) var usvPercents: Bound<String> = Bound("0%")
    private(set) lazy var frameSize: Bound<FrameSize> = Bound(.none)
    private(set) var distance: Bound<Int> = Bound(0)
    private(set) var luminosity: Bound<Int> = Bound(0)
    
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
    private var currentAperture: Float = 0.0
    
    //Detect volume button up/down to start capture
    private var outputVolumeObserve: NSKeyValueObservation?
    private let audioSession = AVAudioSession.sharedInstance()
    private(set) lazy var lightMeter = LightMeter(camera: sdk)
    
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
    
    func requestCameraAccess(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard !sdk.isInitialized else {
            return
        }
        sdk.requestCameraAccess(previewLayer)
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
            lightMeter.iso = currentISO
            lightMeter.speed = currentShutterSpeed
            lightMeter.aperture = currentAperture
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
        let minIndex = 0
        let maxIndex = self.lightMeter.exposureStops.isoStops.count - 1
        let iso = lightMeter.exposureStops.iso(from: lightMeter.iso)
        let index = lightMeter.exposureStops.isoStops.firstIndex(of: iso)!
        let delay = isDarkModeEnabled.value ? 0.5 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sliderMinValue.value = Float(minIndex)
            self.sliderMaxValue.value = Float(maxIndex)
            self.sliderCurrentValue.value = Float(index)
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
        let minIndex = 0
        let maxIndex = lightMeter.exposureStops.speedStops.count - 1
        let speed = lightMeter.exposureStops.speed(from: lightMeter.speed)
        let index = lightMeter.exposureStops.speedStops.firstIndex(of: speed)!
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sliderMinValue.value = Float(minIndex)
            self.sliderMaxValue.value = Float(maxIndex)
            self.sliderCurrentValue.value = Float(index)
        }
        setDarkModeEnabled(false)
    }
    
    func selectAperture() {
        guard currentSetting != .aperture else {
            isSliderEnabled.value = false
            currentSetting = .none
            return
        }
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = true
        currentSetting = .aperture
        let delay = isDarkModeEnabled.value ? 0.5 : 0.0
        let minIndex = 0
        let maxIndex = lightMeter.exposureStops.apertureStops.count - 1
        let aperture = lightMeter.exposureStops.aperture(from: lightMeter.aperture)
        let index = lightMeter.exposureStops.apertureStops.firstIndex(of: aperture)!
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sliderMinValue.value = Float(minIndex)
            self.sliderMaxValue.value = Float(maxIndex)
            self.sliderCurrentValue.value = Float(index)
        }
        setDarkModeEnabled(false)
    }
    
    func hideSliders() {
        isUSVPickerEnabled.value = false
        isWhiteBalanceSliderEnabled.value = false
        isSliderEnabled.value = false
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
        let index = Int(value)
        switch currentSetting {
        case .iso:
            let iso = self.lightMeter.exposureStops.isoStops[index]
            self.lightMeter.iso = iso
            self.isoValue.value = "A \(Int(iso))"
        case .exposure:
            let speed = self.lightMeter.exposureStops.speedStops[index]
            self.lightMeter.speed = speed
            self.exposureValue.value = speedToString(speed)
        case .aperture:
            let aperture = self.lightMeter.exposureStops.apertureStops[index]
            self.lightMeter.aperture = aperture
            self.apertureValue.value = apertureToString(aperture)
        default: break
        }
    }
    
    func update(value: Float) {
        guard sdk.isInitialized else { return }
        setDarkModeEnabled(false)
        let index = Int(value)
        switch currentSetting {
        case .iso:
            let iso = self.lightMeter.exposureStops.isoStops[index]
            self.isoValue.value = "A \(Int(iso))"
        case .exposure:
            let speed = self.lightMeter.exposureStops.speedStops[index]
            self.exposureValue.value = speedToString(speed)
        case .aperture:
            let aperture = self.lightMeter.exposureStops.apertureStops[index]
            self.apertureValue.value = apertureToString(aperture)
        default: break
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
            hideSliders()
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
        lightMeter.iso = currentISO
        lightMeter.speed = currentShutterSpeed
        lightMeter.aperture = currentAperture
        lightMode = .normal
    }
    
    func setupDarkRoomMode() {
        guard lightMode != .darkRoom else {
            return
        }
        currentISO = lightMeter.iso
        currentShutterSpeed = lightMeter.speed
        currentAperture = lightMeter.aperture
        
        lightMeter.iso = 100
        lightMeter.speed = 0.25
        lightMeter.aperture = 1.0
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
            self.lightMeter.iso = 100
            self.lightMeter.speed = 0.25
            self.lightMeter.aperture = 1.0
            try sdk.changeWhiteBalance(tint: sdk.defaultTint, temperature: sdk.defaultTemperature)
            change(series: defaultSeries)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.updateUI()
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
    func pauseCamera() {
        sdk.pause()
    }
    
    func continueCamera() {
        sdk.start()
    }
    
    func calibrateCamera() {
        router.presentCalibrationCamera()
    }
    
    func changeCaptureFormat(_ newFormat: CaptureFormat) {
        self.captureFormat = newFormat
    }
    
    private func makePhoto() {
        if self.brightness > self.maxBrightness || (self.isSingleShootEnabled.value && self.photosCount == 1) {
            //To make sure last photo was saved to photo library
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                //Set it back to Dark-room mode if needed
                if self.isDarkModeEnabled.value {
                    self.lightMeter.iso = 100
                    self.lightMeter.speed = 0.25
                    self.lightMeter.aperture = 1.0
                }
                if !self.isSingleShootEnabled.value {
                    self.brightness = self.minBrightness
                }
                self.isCaptureEnabled.value = true
                self.router.presentPhotosList(
                    maxCount: self.photosCount,
                    format: self.captureFormat
                )
            }
            return
        }
        self.photosCount += 1
        self.capture(brightness: self.brightness)
    }
    
    private var captureDelegates: [Int64 : CaptureDelegate] = [:]
    
    private func capture(brightness: CGFloat) {
        DispatchQueue.main.async {
            let settings = CaptureSettings(
                output: self.sdk.photoOutput,
                format: self.captureFormat
            ).make()
            //set starting brightness to achive flashing effect
            UIScreen.main.brightness = max(brightness - 0.12, self.series.min / 100)
            self.screenBrightness = max(brightness - 0.12, self.series.min / 100)
            self.isFlashEnabled.value = true
            UIScreen.main.brightness = brightness
            
            let params = CaptureParams(
                title: self.series.title,
                iso: self.lightMeter.iso,
                exposure: self.lightMeter.speed,
                aperture: self.lightMeter.aperture,
                tint: self.sdk.tint,
                temperature: self.sdk.temperature,
                brightness: Float(self.brightness),
                distance: self.distance.value
            )
            
            let completion = {
                self.captureDelegates[settings.uniqueID] = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isFlashEnabled.value = false
                    if !self.isSingleShootEnabled.value {
                        let brightness = self.brightness + self.series.step
                        self.brightness = round(brightness * 100) / 100
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.makePhoto()
                    }
                }
            }
            var captureDelegate: CaptureDelegate
            if #available(iOS 14.3, *), self.captureFormat == .raw {
                captureDelegate = RAWCaptureDelegate(params: params)
            } else {
                captureDelegate = TIFFCaptureDelegate(params: params)
            }
            self.captureDelegates[settings.uniqueID] = captureDelegate
            captureDelegate.didFinish = completion
            self.sdk.photoOutput.capturePhoto(with: settings, delegate: captureDelegate)
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
                let params = CaptureParams(
                    title: self.series.title,
                    iso: self.lightMeter.iso,
                    exposure: self.lightMeter.speed,
                    aperture: self.lightMeter.aperture,
                    tint: self.sdk.tint,
                    temperature: self.sdk.temperature,
                    brightness: Float(self.brightness),
                    distance: self.distance.value
                )
                options.originalFilename = params.makeFileName()
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
        isoCancellabel = lightMeter.$iso.sink { [unowned self] value in
            self.isoValue.value = "A \(value)"
        }
        exposureCancellabel = lightMeter.$speed.sink { [unowned self] value in
            self.exposureValue.value = speedToString(value)
        }
        apertureCancellabel = lightMeter.$aperture.sink { [unowned self] aperture in
            self.apertureValue.value = apertureToString(aperture)
        }
        lightMeter.startUpdating()
    }
    
    func updateDistance(_ distance: Int) {
        self.distance.value = distance
    }
    
    func updateLuminosity(_ luminosity: Int) {
        self.luminosity.value = luminosity
    }
    
    private func updateUI() {
        self.lightMeter.iso = 100
        self.lightMeter.speed = 0.25
        self.lightMeter.aperture = 1.0
        self.isoValue.value = "A \(Int(sdk.iso))"
        self.exposureValue.value = String(format: "%0.2f", sdk.shutterSpeed)
        self.wbValue.value = "AWB"
        self.usvValue.value = series.title
        self.tintLabel.value = "\(Int(sdk.tint))"
        self.temperatureLabel.value = "\(Int(sdk.temperature))"
    }
}
