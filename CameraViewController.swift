//
//  CameraViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

class CameraViewController: UIViewController {
    @IBOutlet private weak var containerView: CameraPreviewView!
    @IBOutlet private weak var captureButton: UIButton!
    
    @IBAction private func cancelButtonPressed(_ button: UIButton) {
       //TODO: dismiss screen here
    }
    
    @IBAction private func cameraButtonPressed(_ button: UIButton) {
        viewModel.capture()
    }
    
    var viewModel: CameraVM!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerView.videoPreviewLayer.session = viewModel.captureSession
        containerView.videoPreviewLayer.videoGravity = .resizeAspectFill
        viewModel.requestCameraAccess()
    }
}
