//
//  DistanceCalibrationRouter.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import UIKit

class DistanceCalibrationRouter {
    private weak var controller: UIViewController!
    private let isRecalibration: Bool
    private var isPresented: Bool = false
    
    init(controller: UIViewController, isRecalibration: Bool = false) {
        self.controller = controller
        self.isRecalibration = isRecalibration
    }

    func presentCamera() {
        guard !isPresented else { return }
        if isRecalibration {
            controller.dismiss(animated: true)
        } else {
            let controller = ScreenBuilder.camera()
            controller.modalPresentationStyle = .fullScreen
            self.controller.present(controller, animated: true)
        }
        isPresented = true
    }
}
