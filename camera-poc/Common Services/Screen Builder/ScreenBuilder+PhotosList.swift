//
//  ScreenBuilder+PhotosList.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit

extension ScreenBuilder {
    struct PhotosList {
        static func photosList(numberOfPhotos: Int) -> UIViewController {
            let controller = PhotosListViewController.instantiateFromStoryboard(.photosList)
            let router = PhotosListRouter(controller: controller)
            let viewModel = PhotosListVM(numberOfPhotos: numberOfPhotos, router: router)
            controller.viewModel = viewModel
            let navController = UINavigationController(rootViewController: controller)
            navController.modalPresentationStyle = .fullScreen
            return navController
        }
    }
}
