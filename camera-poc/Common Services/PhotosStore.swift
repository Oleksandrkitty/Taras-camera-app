//
//  PhotosStore.swift
//  Astarte
//
//  Created by Taras Chernyshenko on 28.03.2022.
//

import UIKit
import Photos

struct PhotosStore {
    func fetchAssets(totalImageCountNeeded: Int) -> [PHAsset] {
        var assets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.fetchLimit = totalImageCountNeeded
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        for i in 0..<fetchResult.count {
            let asset = fetchResult.object(at: i) as PHAsset
            if let _ = PHAssetResource.assetResources(for: asset).first {
                assets.append(asset)
            }
        }
        return assets
    }
    
    func fetchPhotos(_ assets: [PHAsset]) async -> [UIImage] {
        var photos: [UIImage] = []
        for asset in assets {
            if let photo = await fetchPhoto(asset) {
                photos.append(photo)
            }
        }
        return photos
    }
    
    func fetchPhoto(_ asset: PHAsset) async -> UIImage? {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: .zero,
                contentMode: .aspectFill,
                options: requestOptions) { (image, _) in
                continuation.resume(returning: image)
            }
        }
    }
    
    func save(asset: PHAsset, name: String, format: CaptureFormat) async throws -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        let fileURL = imagesDirectory.appendingPathComponent(name).appendingPathExtension(format.fileExtension)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        
        let resource = PHAssetResource.assetResources(for: asset).first!
        let resourceManager = PHAssetResourceManager.default()
        try await resourceManager.writeData(
            for: resource,
            toFile: fileURL,
            options: nil
        )
        return fileURL
    }
    
    func createImageDirectoryIfNeeded() {
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

extension PHAsset {
    var type: String? {
        guard let resource = PHAssetResource.assetResources(for: self).first else {
            return nil
        }
        return resource.uniformTypeIdentifier
    }
    
    var filename: String? {
        guard let resource = PHAssetResource.assetResources(for: self).first else {
            return nil
        }
        return resource.originalFilename
    }
}
