//
//  PhotosListVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit
import Photos

class PhotosListVM {
    private let router: PhotosListRouting
    private(set) var photos: Bound<[UIImage]> = Bound([])
    private var assets: [PHAsset] = []
    init(numberOfPhotos: Int, router: PhotosListRouting) {
        self.router = router
        fetchPhotos(totalImageCountNeeded: numberOfPhotos)
        createImageDirectoryIfNeeded()
    }
    
    func upload() {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        router.showProgress()
        let group = DispatchGroup()
        for asset in self.assets {
            if let resource = PHAssetResource.assetResources(for: asset).first {
                let filename = resource.originalFilename
                group.enter()
                PHImageManager.default().requestImage(for: asset, targetSize: .zero, contentMode: .aspectFill, options: requestOptions) { (image, _) in
                    if let image = image, let url = self.saveImage(imageName: filename, image: image) {
                        AWSS3Service.shared.uploadFileFromURL(url, conentType: "image/jpeg", progress: nil) { _, error in
                            group.leave()
                            guard let error = error else {
                                return
                            }
                            assertionFailure(error.localizedDescription)
                        }
                    } else {
                        group.leave()
                    }
                }
            }
        }
        group.notify(queue: .main) {
            self.router.hideProgress()
            self.router.dismiss()
        }
    }
    
    func fetchPhotos(totalImageCountNeeded: Int) {
        var photos: [UIImage] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = totalImageCountNeeded
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        let group = DispatchGroup()
        for i in 0..<fetchResult.count {
            let asset = fetchResult.object(at: i) as PHAsset
            if let resource = PHAssetResource.assetResources(for: asset).first {
                print(resource.originalFilename)
                group.enter()
                self.assets.append(asset)
                PHImageManager.default().requestImage(for: asset, targetSize: .zero, contentMode: .aspectFill, options: requestOptions) { (image, _) in
                    if let image = image {
                        photos += [image]
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.photos.value = photos
        }
    }
    
    func saveImage(imageName: String, image: UIImage) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let fileName = imageName
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            assertionFailure("Error saving file with error \(error)")
            return nil
        }
        return fileURL
    }
    
    private func createImageDirectoryIfNeeded() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        do {
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } else {
                //Clear directory and create it again in order to remove all files
                try fileManager.removeItem(at: imagesDirectory)
                createImageDirectoryIfNeeded()
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}
