//
//  LoginRouter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 20.09.2021.
//

import UIKit

class LoginRouter {
    private weak var controller: UIViewController!

    init(controller: UIViewController) {
        self.controller = controller
    }

    func presentCamera() {
        let controller = ScreenBuilder.camera()
        controller.modalPresentationStyle = .fullScreen
        self.controller.present(controller, animated: false)
    }
}
