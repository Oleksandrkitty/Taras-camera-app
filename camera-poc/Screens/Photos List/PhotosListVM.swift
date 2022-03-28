//
//  PhotosListVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit
import Photos

class PhotosListVM {
    typealias Photo = (photo: UIImage, name: String, type: String)
    private let router: PhotosListRouting
    private let authService = AuthService()
    private let photosStore = PhotosStore()
    private(set) var photos: Bound<[UIImage]> = Bound([])
    private var assets: [PHAsset] = []
    
    init(numberOfPhotos: Int, router: PhotosListRouting) {
        self.router = router
        self.setup(numberOfPhotos: numberOfPhotos)
    }

    func auth() {
        router.showAuth(delegate: self)
    }

    func upload() {
        guard let userName = authService.userName else {
            auth()
            return
        }
        router.showProgress()
        Task {
            var result: [Photo] = []
            for asset in self.assets {
                guard let filename = asset.filename,
                    let type = asset.type,
                    let photo = await photosStore.fetchPhoto(asset) else {
                    continue
                }
                let imageName = "\(userName)_\(filename)"
                result.append((photo, imageName, type))
            }
            self.upload(photos: result)
        }
    }
    
    func share() {
        guard let userName = authService.userName else {
            auth()
            return
        }
        Task {
            var urls: [URL] = []
            for asset in self.assets {
                guard let filename = asset.filename,
                    let photo = await photosStore.fetchPhoto(asset) else {
                    continue
                }
                let imageName = "\(userName)_\(filename)"
                guard let url = self.photosStore.save(image: photo, name: imageName) else {
                    continue
                }
                urls.append(url)
            }
            let result = urls
            await MainActor.run {
                self.router.showSharing(result)
            }
        }
    }
    
    private func upload(photos: [Photo]) {
        let group = DispatchGroup()
        for photo in photos {
            group.enter()
            upload(photo.photo, name: photo.name, type: photo.type) {
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.router.hideProgress()
            self.router.dismiss()
        }
    }
}

extension PhotosListVM {
    private func setup(numberOfPhotos: Int) {
        Task {
            let assets = self.photosStore.fetchAssets(
                totalImageCountNeeded: numberOfPhotos
            )
            let photos = await self.photosStore.fetchPhotos(assets)
            self.assets = assets
            await MainActor.run {
                self.photos.value = photos
            }
        }
    }
    
    private func upload(_ image: UIImage, name: String, type: String, completion: @escaping () -> Void) {
        guard let url = self.photosStore.save(image: image, name: name) else {
            completion()
            return
        }
        print("Start uploading \(name)...")
        AWSS3Service.shared.uploadFileFromURL(url, conentType: type, progress: nil) { _,error in
            if let error = error {
                print("Error \(error.localizedDescription), while uploading \(name)")
            } else {
                print("Uploaded \(name)!")
            }
            completion()
        }
    }
}

extension PhotosListVM: AuthVMDelegate {
    func didAuthorized() {
        upload()
    }
}
