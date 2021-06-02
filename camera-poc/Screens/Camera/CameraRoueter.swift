//
//  CameraRoueter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

protocol CameraRouting {
    func presentCameraDeniedAlert()
}

struct CameraRouter: CameraRouting {
    private weak var controller: UIViewController!
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    func presentCameraDeniedAlert() {
        let alert = UIAlertController(
            title: "Access Denied",
            message: "Access to the camera was denied. Please, go to the Settings and allow camera access.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        
        controller.present(alert, animated: true)
    }
}
