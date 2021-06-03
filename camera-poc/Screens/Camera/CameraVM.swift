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
    private let router: CameraRouting
    private let photoOutput = AVCapturePhotoOutput()
    private var videoInput: AVCaptureDeviceInput?
    let captureSession: AVCaptureSession = AVCaptureSession()
    
    private var screenBrightness: CGFloat = 0.5
    private(set) var isFlashEnabled: Bound<Bool> = Bound(false)
    private(set) var flashBrightness: Bound<CGFloat> = Bound(0.0)
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
    
    func change(series: BrigtnessSeries) {
        self.series = series
    }

    func capture() {
        brightness = minBrightness
        makePhoto()
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

struct BrigtnessSeries {
    let min: CGFloat
    let max: CGFloat
    let step: CGFloat
}

let Low = BrigtnessSeries(min: 10, max: 40, step: 0.05)
let Medium = BrigtnessSeries(min: 45, max: 70, step: 0.05)
let High = BrigtnessSeries(min: 75, max: 100, step: 0.05)
