//
//  RAWCaptureDelegate.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import Photos

@available(iOS 14.3, *)
class RAWCaptureDelegate: CaptureDelegate {
    private let params: CaptureParams
    private var photoData: Data?
    
    init(params: CaptureParams) {
        self.params = params
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(error!)")
            return
        }
        guard let photoData = photo.fileDataRepresentation() else {
            print("No photo data to write.")
            return
        }
        if photo.isRawPhoto {
            self.photoData = photoData
        }
    }
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?) {
        defer { didFinish?() }
        
        guard error == nil else {
            print("Error capturing photo: \(error!)")
            return
        }
        guard let data = photoData else {
            print("The expected photo data isn't available.")
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                options.originalFilename = self.params.makeFileName()
                creationRequest.addResource(
                    with: .photo,
                    data: data,
                    options: options
                )
            } completionHandler: { success, error in
                if let error = error {
                    assertionFailure(error.localizedDescription)
                }
                if success {
                    print("RAW photo was saved to photo library")
                }
            }
        }
    }
}
