//
//  CameraRoueter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 02.06.2021.
//

import UIKit

protocol CameraRouting {
    func presentCameraDeniedAlert()
    func presentPhotosList(maxCount: Int)
    func presentChangeLight(from: Float, to: Float)
    func presentFamilyDevicePicker()
}

struct CameraRouter: CameraRouting {
    private weak var controller: CameraViewController!
    
    init(controller: CameraViewController) {
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
    
    func presentPhotosList(maxCount: Int) {
        let controller = ScreenBuilder.PhotosList.photosList(numberOfPhotos: maxCount)
        self.controller.present(controller, animated: true)
    }
    
    func presentChangeLight(from: Float, to: Float) {
        var values: [Float] = []
        for i in stride(from: from, to: to + 5, by: 5) {
            values.append(i)
        }
        controller.presentLightPicker(values: values)
    }
    
    func presentFamilyDevicePicker() {
        controller.presentFamilyDevicePicker()
    }
}
