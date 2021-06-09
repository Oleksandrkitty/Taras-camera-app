//
//  PhotosListVM.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit
import Photos

class PhotosListVM {
    private(set) var photos: Bound<[UIImage]> = Bound([])
    private var assets: [PHAsset] = []
    init(numberOfPhotos: Int) {
        fetchPhotos(totalImageCountNeeded: numberOfPhotos)
    }
    
    func upload() {
        //TODO: upload to the SharePoint/GoogleDrive/etc
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
                group.enter()
                self.assets.append(asset)
                PHImageManager.default().requestImage(for: asset, targetSize: .zero, contentMode: .aspectFill, options: requestOptions) { (image, _) in
                    if let image = image {
                        photos += [image]
                    }
                    group.leave()
                }
                print(resource.originalFilename)
            }
        }
        
        group.notify(queue: .main) {
            self.photos.value = photos
        }
    }
}
