//
//  ImageCollectionViewCell.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var selectedImageView: UIImageView!
    
    func set(photo: UIImage, selected isSelected: Bool) {
        imageView.image = photo
        selectedImageView.isHidden = !isSelected
    }
}
