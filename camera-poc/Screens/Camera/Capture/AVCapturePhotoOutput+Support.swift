//
//  AVCapturePhotoOutput+Support.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 13.06.2022.
//

import AVFoundation

extension AVCapturePhotoOutput {
    var isRawSupported: Bool {
        guard #available(iOS 14.3, *) else {
            return false
        }
        let query = isAppleProRAWEnabled ?
            { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) } :
            { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }

        guard let _ =
                availableRawPhotoPixelFormatTypes.first(where: query) else {
            return false
        }
        return true
    }
    
    var isDNGSupported: Bool {
        if let _ = supportedPhotoPixelFormatTypes(for: .dng).first {
            return true
        }
        return false
    }
}
