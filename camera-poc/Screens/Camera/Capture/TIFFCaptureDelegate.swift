//
//  TIFFCaptureDelegate.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import Photos

class TIFFCaptureDelegate: CaptureDelegate {
    private let params: CaptureParams
    
    init(params: CaptureParams) {
        self.params = params
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { didFinish?() }
        
        guard error == nil else {
            print("Error capturing photo: \(error!)")
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            print("The expected photo data isn't available.")
            return
        }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
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
                    print("TIFF photo was saved to photo library")
                }
            }
        }
    }
}
