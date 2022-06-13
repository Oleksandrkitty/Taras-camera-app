//
//  CaptureSettings.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import AVFoundation

struct CaptureSettings {
    private let output: AVCapturePhotoOutput
    private let format: CaptureFormat
    
    init(output: AVCapturePhotoOutput, format: CaptureFormat) {
        self.output = output
        self.format = format
    }
    
    func make() -> AVCapturePhotoSettings {
        if format == .raw {
            if #available(iOS 14.3, *), output.isRawSupported {
                return makeRAWSettings()
            }
            if output.isDNGSupported {
                return makeDNGSettings()
            }
        }
        return makeTIFFSettings()
    }
    
    @available(iOS 14.3, *)
    private func makeRAWSettings() -> AVCapturePhotoSettings {
        let query = output.isAppleProRAWEnabled ?
            { AVCapturePhotoOutput.isAppleProRAWPixelFormat($0) } :
            { AVCapturePhotoOutput.isBayerRAWPixelFormat($0) }

        // Retrieve the RAW format, favoring Apple ProRAW when it's in an enabled state.
        guard let rawFormat =
                output.availableRawPhotoPixelFormatTypes.first(where: query) else {
            fatalError("No RAW format found.")
        }

        // Capture a RAW format photo, along with a processed format photo.
        let processedFormat = [AVVideoCodecKey: AVVideoCodecType.hevc]
        let settings =  AVCapturePhotoSettings(
            rawPixelFormatType: rawFormat,
            processedFormat: processedFormat
        )
        settings.flashMode = .off
        return settings
    }
    
    private func makeDNGSettings() -> AVCapturePhotoSettings {
        var settings: AVCapturePhotoSettings
        if let uncompressedPixelType = output.supportedPhotoPixelFormatTypes(for: .dng).first {
            settings = AVCapturePhotoSettings(format: [
                kCVPixelBufferPixelFormatTypeKey as String : uncompressedPixelType
            ])
        } else {
            settings = AVCapturePhotoSettings()
        }
        settings.flashMode = .off
        return settings
    }

    private func makeTIFFSettings() -> AVCapturePhotoSettings {
        var settings: AVCapturePhotoSettings
        if let uncompressedPixelType = output.supportedPhotoPixelFormatTypes(for: .tif).first {
            settings = AVCapturePhotoSettings(format: [
                kCVPixelBufferPixelFormatTypeKey as String : uncompressedPixelType
            ])
        } else {
            settings = AVCapturePhotoSettings()
        }
        settings.flashMode = .off
        return settings
    }
}
