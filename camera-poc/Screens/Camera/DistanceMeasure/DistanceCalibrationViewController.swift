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
    @IBOutlet private weak var calibrateButton: UIButton! {
        didSet {
            calibrateButton.layer.cornerRadius = 8.0
            calibrateButton.clipsToBounds = true
        }
    }
    
    @IBAction private func calibrateButtonPressed(_ button: UIButton) {
        viewModel.measureEyesDistance()
    }
    
    private lazy var ovalOverlayView = OvalOverlayView(
        frame: containerView.bounds,
        topSpace: 125.0,
        backgroundColor: UIColor.black.withAlphaComponent(0.5)
    )
    
    private var isOverlayViewInGreen: Bool = false
    
    var viewModel: DistanceCalibrationVM! {
        didSet {
            viewModel.isFaceDistanceCorrect.bind { [weak self] isCorrect in
                guard let self = self else { return }
                if self.isOverlayViewInGreen != isCorrect {
                    self.ovalOverlayView.frameColor = isCorrect ? .green : .white
                    self.isOverlayViewInGreen = isCorrect
                }
                
            }
            viewModel.distance.bind { [weak self] distance in
                self?.distanceLabel.text = "\(distance)cm"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.addSubview(viewModel.preview)
        viewModel.preview.translatesAutoresizingMaskIntoConstraints = false
        viewModel.preview.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        viewModel.preview.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        viewModel.preview.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        viewModel.preview.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        containerView.addSubview(viewModel.sceneView)
        viewModel.sceneView.translatesAutoresizingMaskIntoConstraints = false
        viewModel.sceneView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        viewModel.sceneView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        viewModel.sceneView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        viewModel.sceneView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        
        referalDistanceLabel.text = "Please, move camera on \(viewModel.referalDistance)cm from face"
        viewModel.setup()
        viewModel.calibrate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        containerView.addSubview(ovalOverlayView)
    }
}
