//
//  ScreenBuilder+Camera.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

extension ScreenBuilder {
    static func camera() -> UIViewController {
        let controller = CameraViewController.instantiateFromStoryboard(.camera)
        let viewModel = CameraVM()
        controller.viewModel = viewModel
        return controller
    }
}
