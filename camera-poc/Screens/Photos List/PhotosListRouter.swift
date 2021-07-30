//
//  PhotosListRouter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 11.06.2021.
//

import UIKit
import Photos

protocol PhotosListRouting {
    func dismiss()
    func showProgress()
    func showProgress(_ progress: Float)
    func hideProgress()
    func showAuth(delegate: AuthVMDelegate)
}

struct PhotosListRouter: PhotosListRouting {
    private weak var controller: PhotosListViewController!
    
    init(controller: PhotosListViewController) {
        self.controller = controller
    }
    
    func dismiss() {
        controller.dismiss(animated: true)
    }
    
    func showProgress() {
        controller.showProgress()
    }
    
    func showProgress(_ progress: Float) {

    }
    
    func hideProgress() {
        controller.hideProgress()
    }

    func showAuth(delegate: AuthVMDelegate) {
        let controller = ScreenBuilder.Auth.auth(delegate: delegate)
        self.controller.show(controller, sender: nil)
    }
}
