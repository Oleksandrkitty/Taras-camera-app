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
            let viewModel = PhotosListVM(numberOfPhotos: numberOfPhotos)
            controller.viewModel = viewModel
            let navController = UINavigationController(rootViewController: controller)
            navController.modalPresentationStyle = .fullScreen
            return navController
        }
    }
}
