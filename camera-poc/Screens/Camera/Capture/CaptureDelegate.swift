//
//  CaptureDelegate.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.06.2022.
//

import Photos

class CaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var didFinish: (() -> Void)?
}
