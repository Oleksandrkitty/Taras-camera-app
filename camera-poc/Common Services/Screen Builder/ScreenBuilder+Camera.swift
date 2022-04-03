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
        let router = CameraRouter(controller: controller)
        let viewModel = CameraVM(router: router)
        controller.viewModel = viewModel
        return controller
    }
    
    static func calibrate(isRecalibration: Bool = false) -> UIViewController {
        let controller = DistanceCalibrationViewController.instantiateFromStoryboard(.distanceCalibration)
        let router = DistanceCalibrationRouter(
            controller: controller,
            isRecalibration: isRecalibration
        )
        let viewModel = DistanceCalibrationVM(router: router)
        controller.viewModel = viewModel
        return controller
    }
}
