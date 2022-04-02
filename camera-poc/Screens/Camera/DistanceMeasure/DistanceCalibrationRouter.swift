//
//  DistanceCalibrationRouter.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 02.04.2022.
//

import UIKit

class DistanceCalibrationRouter {
    private weak var controller: UIViewController!

    init(controller: UIViewController) {
        self.controller = controller
    }

    func presentCamera() {
        if controller.isBeingPresented {
            controller.dismiss(animated: true)
        } else {
            let controller = ScreenBuilder.camera()
            controller.modalPresentationStyle = .fullScreen
            self.controller.present(controller, animated: true)
        }
    }
}
