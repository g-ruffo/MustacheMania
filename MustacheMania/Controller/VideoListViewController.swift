//
//  VideoListViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
import AVFoundation
import AVKit

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
        // Add notification observer to listen for database changes.
        NotificationCenter.default.addObserver(self, selector: #selector(videosUpdated), name: NSNotification.Name("Update"), object: nil)
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    @objc func videosUpdated() { coreDataService.loadVideosFromDatabase() }
    
    func fileInDocumentsDirectory(fileName: String) -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let url = documentsURL {
            let fileURL = url.appendingPathComponent(fileName)
            return fileURL
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
    
    func editPlayAlert(atIndex index: Int) {
        let video = savedVideos[index]
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Edit or Play Video", message: nil, preferredStyle: .alert)
            alertController.addTextField { field in
                field.text = video.tag
                field.returnKeyType = .done
            }

            alertController.addAction(UIAlertAction(title: "Play", style: .default, handler: { _ in
                if let videoName = video.videoName {
                    let videoPath = self.fileInDocumentsDirectory(fileName: videoName)
                    if let url = videoPath {
                        self.playVideo(atUrl: url)
                    }
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                guard let text = alertController.textFields?.first?.text else { return }
                self.coreDataService.updateVideo(newTag: text, atIndex: index)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                if let videoName = video.videoName {
                    let videoPath = self.fileInDocumentsDirectory(fileName: videoName)
                    if let url = videoPath {
                        do {
                            try FileManager.default.removeItem(at: url)
                            self.coreDataService.deleteVideo(atIndex: index)
                        } catch {
                            print("Error deleting video = \(error.localizedDescription)")
                        }
                    }
                }
            }))

            self.present(alertController, animated: true, completion: nil)
        }
    }
    // Play selected video from URL.
    func playVideo(atUrl url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension VideoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        editPlayAlert(atIndex: indexPath.row)
    }
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
            let videoPath = fileInDocumentsDirectory(fileName: fileName)
            if let url = videoPath {
                // Set the cells image view.
                cell.videoPreviewImage.image = getThumbnailImage(forUrl: url)
                cell.videoPreviewImage.contentMode = .scaleAspectFill
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewFlowLayout
extension VideoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate the cell size.
        let cellsPerRow: CGFloat = 3
        let width = collectionView.bounds.width / cellsPerRow
        return CGSize(width: width - cellsPerRow, height: width - cellsPerRow)
    }
}

extension VideoListViewController: CoreDataServiceDelegate {
    func videosHaveLoaded(_ coreDataService: CoreDataService, loadedVideos: [RecordedVideoItem]) {
        savedVideos = loadedVideos
        DispatchQueue.main.async { self.collectionView.reloadData() }
    }
}

