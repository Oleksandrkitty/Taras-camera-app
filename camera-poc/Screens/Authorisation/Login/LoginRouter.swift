//
//  LoginRouter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 20.09.2021.
//

import UIKit

class LoginRouter {
    private weak var controller: UIViewController!
    private let loginService = LoginService()
    init(controller: UIViewController) {
        self.controller = controller
    }

    func presentCamera() {
        if loginService.isCameraCalibrated {
            let controller = ScreenBuilder.camera()
            controller.modalPresentationStyle = .fullScreen
            self.controller.present(controller, animated: false)
        } else {
            let controller = ScreenBuilder.calibrate()
            controller.modalPresentationStyle = .fullScreen
            self.controller.present(controller, animated: false)
        }
    }
}
