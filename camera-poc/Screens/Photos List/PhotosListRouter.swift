//
//  PhotosListRouter.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 11.06.2021.
//

import UIKit
import Photos

protocol PhotosListRouting {
    func presentShareDialog(_ items: [URL])
}

struct PhotosListRouter: PhotosListRouting {
    private weak var controller: UIViewController!
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    func presentShareDialog(_ items: [URL]) {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.controller.present(controller, animated: true)
    }
}
