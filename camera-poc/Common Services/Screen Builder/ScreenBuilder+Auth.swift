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
            let controller = AuthViewController.instantiateInitial(from: .auth)
            let router = AuthRouter(controller: controller)
            let viewModel = AuthVM(router: router, delegate: delegate)
            controller.viewModel = viewModel
            return controller
        }
    }
}
