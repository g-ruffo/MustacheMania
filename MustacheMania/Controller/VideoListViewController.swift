//
//  VideoListViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
import AVFoundation

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
        coreDataService.loadVideosFromDatabase()
        
        NotificationCenter.default.addObserver(self, selector: #selector(videosUpdated), name: NSNotification.Name("Update"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func videosUpdated() {
        coreDataService.loadVideosFromDatabase()
    }
    
    func fileInDocumentsDirectory(fileName: String) -> String? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let url = documentsURL {
            let fileURL = url.appendingPathComponent(fileName)
            return fileURL.path
        }
            return nil
        }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
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
        let video = savedVideos[indexPath.row]
        cell.durationLabel.text = "\(video.duration ?? "")"
        cell.tagLabel.text = video.tag
        if let fileName = video.videoName {
            let destinationPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let videoPath = destinationPath?.appendingPathComponent(fileName)
            if let path = videoPath {
                cell.videoPreviewImage.image = getThumbnailImage(forUrl: path)
                cell.videoPreviewImage.contentMode = .scaleAspectFill
            }
        }
        
        return cell
    }
    
    
}

// MARK: - UICollectionViewFlowLayout
extension VideoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 120, height: 120)
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

