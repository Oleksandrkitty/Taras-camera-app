//
//  PhotosListViewController.swift
//  camera-poc
//
//  Created by Taras Chernyshenko on 09.06.2021.
//

import UIKit

class PhotosListViewController: UIViewController {
    @IBOutlet private weak var progressView: UIView! {
        didSet {
            progressView.isHidden = true
        }
    }
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView? {
        didSet {
            collectionView?.register(ImageCollectionViewCell.nib, forCellWithReuseIdentifier: "ImageCollectionViewCell")
            collectionView?.dataSource = self
            collectionView?.delegate = self
        }
    }
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    @IBAction private func uploadButtonPressed(_ button: UIButton) {
        viewModel.auth()
    }
    
    var viewModel: PhotosListVM! {
        didSet {
            viewModel.photos.bind { [weak self] _ in
                self?.collectionView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Upload"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self, action: #selector(share)
        )
    }
    
    func showProgress() {
        progressView.isHidden = false
        progressLabel.text = "Uploading..."
        spinner.startAnimating()
    }
    
    func showProgress(_ progress: Float) {
        progressLabel.text = "Uploading \(Int(progress * 100))%"
    }
    
    func hideProgress() {
        progressView.isHidden = true
        spinner.stopAnimating()
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func share() {
        viewModel.share()
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
