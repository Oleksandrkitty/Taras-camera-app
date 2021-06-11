//
//  PhotosListViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit

class PhotosListViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(ImageCollectionViewCell.nib, forCellWithReuseIdentifier: "ImageCollectionViewCell")
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }
    
    @IBAction private func uploadButtonPressed(_ button: UIButton) {
        viewModel.upload()
    }
    
    var viewModel: PhotosListVM! {
        didSet {
            viewModel.photos.bind { [weak self] _ in
                self?.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Upload"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
}

extension PhotosListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ImageCollectionViewCell",
            for: indexPath
        ) as! ImageCollectionViewCell
        let photo = viewModel.photos.value[indexPath.row]
        cell.set(photo: photo, selected: false)
        return cell
    }
}

extension PhotosListViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width / 3 - 4
        return CGSize(width: width, height: width)
    }
}
