//
//  CameraViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

class CameraViewController: UIViewController {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var captureButton: UIButton!
    
    @IBAction private func cancelButtonPressed(_ button: UIButton) {
       //TODO: dismiss screen here
    }
    
    @IBAction private func cameraButtonPressed(_ button: UIButton) {
        print("Capture")
    }
    
    var viewModel: CameraVM!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
