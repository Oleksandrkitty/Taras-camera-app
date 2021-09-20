//
//  ScreenBuilder+Auth.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 30.07.2021.
//

import UIKit

extension ScreenBuilder {
    struct Auth {
        static func auth(delegate: AuthVMDelegate) -> UIViewController {
            let controller = AuthViewController.instantiateFromStoryboard(.auth)
            let router = AuthRouter(controller: controller)
            let viewModel = AuthVM(router: router, delegate: delegate)
            controller.viewModel = viewModel
            return controller
        }

        static func login() -> UIViewController {
            let controller = LoginViewController.instantiateFromStoryboard(.auth)
            let router = LoginRouter(controller: controller)
            let viewModel = LoginVM(router: router)
            controller.viewModel = viewModel
            return controller
        }
    }
}
