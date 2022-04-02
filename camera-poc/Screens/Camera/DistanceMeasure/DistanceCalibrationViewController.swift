//
//  DistanceCalibrationViewController.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import UIKit
import ARKit

class DistanceCalibrationViewController: UIViewController {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var calibrationView: UIView!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var referalDistanceLabel: UILabel!
    private lazy var ovalOverlayView = OvalOverlayView(
        frame: containerView.bounds,
        topSpace: 125.0,
        backgroundColor: UIColor.black.withAlphaComponent(0.5)
    )
    
    var viewModel: DistanceCalibrationVM! {
        didSet {
            viewModel.isStepCompleted.bind { [weak self] isCompleted in
                self?.ovalOverlayView.frameColor = .green
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.ovalOverlayView.frameColor = .white
                }
            }
            viewModel.distance.bind { [weak self] distance in
                self?.distanceLabel.text = "\(distance)cm"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.layer.addSublayer(viewModel.previewLayer)
        containerView.addSubview(viewModel.sceneView)
        viewModel.sceneView.translatesAutoresizingMaskIntoConstraints = false
        viewModel.sceneView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        viewModel.sceneView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        viewModel.sceneView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        viewModel.sceneView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        
        referalDistanceLabel.text = "Please, move camera on \(viewModel.referalDistance)cm from face"
        viewModel.calibrate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerView.addSubview(ovalOverlayView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.viewModel.previewLayer.frame = self.containerView.frame
    }
}
