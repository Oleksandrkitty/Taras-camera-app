//
//  CameraPreviewView.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit
import AVKit

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
