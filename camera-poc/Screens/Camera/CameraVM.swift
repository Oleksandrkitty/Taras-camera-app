//
//  CameraVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import Foundation
import AVKit

class CameraVM {
    private let router: CameraRouting
    let captureSession: AVCaptureSession = AVCaptureSession()
    
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
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            assertionFailure("Can't add video input")
        }
        
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.sessionPreset = .photo
            captureSession.addOutput(photoOutput)
        }
        captureSession.commitConfiguration()
        captureSession.startRunning()
    }
}
