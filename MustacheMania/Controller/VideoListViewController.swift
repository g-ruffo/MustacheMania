//
//  VideoListViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit

class VideoListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var savedVideos: [RecordedVideoItem] = []
    
    private var coreDataService = CoreDataService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set collection views delegate and datasource.
        collectionView.delegate = self
        collectionView.dataSource = self
        // Set CoreDataServices delegate.
        coreDataService.delegate = self
        // Set navigation title to large.
        navigationController?.navigationBar.prefersLargeTitles = true
        // Register reusable cell with collection view.
        collectionView.register(VideoCell.nib(), forCellWithReuseIdentifier: K.Cell.videoCell)
    }
    
}

// MARK: - UICollectionViewDelegate
extension VideoListViewController: UICollectionViewDelegate {
    
}

// MARK: - UICollectionViewDataSource
extension VideoListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: K.Cell.videoCell, for: indexPath) as! VideoCell
        
        return cell
    }
    
    
}

// MARK: - UICollectionViewFlowLayout
extension VideoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = collectionView.bounds.width / 4
        return CGSize(width: size, height: size)
    }
}

extension VideoListViewController: CoreDataServiceDelegate {
    func videosHaveLoaded(_ coreDataService: CoreDataService, loadedVideos: [RecordedVideoItem]) {
        savedVideos = loadedVideos
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

