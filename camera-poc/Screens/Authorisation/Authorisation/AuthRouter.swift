//
//  AuthRouter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 30.07.2021.
//

import UIKit

class AuthRouter {
    private weak var controller: UIViewController!

    init(controller: UIViewController) {
        self.controller = controller
    }

    func dismiss() {
        controller.navigationController?.popViewController(animated: false)
    }
}
