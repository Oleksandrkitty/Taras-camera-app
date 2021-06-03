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
    @IBOutlet private weak var flashView: UIView!
    @IBOutlet private weak var seriesLabel: UILabel!

    @IBAction private func cancelButtonPressed(_ button: UIButton) {
       //TODO: dismiss screen here
    }
    
    @IBAction private func lowButtonPressed(_ button: UIButton) {
        viewModel.change(series: Low)
    }
    
    @IBAction private func mediumButtonPressed(_ button: UIButton) {
        viewModel.change(series: Medium)
    }
    
    @IBAction private func highButtonPressed(_ button: UIButton) {
        viewModel.change(series: High)
    }
    
    @IBAction private func cameraButtonPressed(_ button: UIButton) {
        viewModel.capture()
    }
    
    var viewModel: CameraVM! {
        didSet {
            viewModel.isFlashEnabled.bind { [unowned self] isEnabled in
                if isEnabled {
                    self.flashView.isHidden = false
                } else {
                    UIView.animate(withDuration: 0.1) {
                        self.flashView.isHidden = true
                    }
                }
            }
            viewModel.seriesString.bind { [unowned self] string in
                self.seriesLabel.text = string
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerView.videoPreviewLayer.session = viewModel.captureSession
        containerView.videoPreviewLayer.videoGravity = .resizeAspectFill
        viewModel.requestCameraAccess()
    }
}
