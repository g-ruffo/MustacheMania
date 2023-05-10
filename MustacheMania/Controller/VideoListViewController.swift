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
        // Get the path of the users document directory.
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let url = documentsURL {
            // Append the video items file name to the URL.
            let fileURL = url.appendingPathComponent(fileName)
            return fileURL
        }
            return nil
        }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        // Get the video file from the URL location.
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            // Create image from the video file.
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            // Return the newly created image as a UIImage.
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
                // Set the text fields text to the existing video items tag.
                field.text = video.tag
                field.returnKeyType = .done
            }

            alertController.addAction(UIAlertAction(title: "Play", style: .default, handler: { _ in
                if let videoName = video.videoName {
                    // Retrieve the documents directory and append the file name to the URL.
                    let videoPath = self.fileInDocumentsDirectory(fileName: videoName)
                    if let url = videoPath {
                        // Play the video data located at the given URL.
                        self.playVideo(atUrl: url)
                    }
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                // Get the users text input from the text field.
                guard let text = alertController.textFields?.first?.text else { return }
                // Update the video items title in the database.
                self.coreDataService.updateVideo(newTag: text, atIndex: index)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                if let videoName = video.videoName {
                    // Get the URL for the video to delete.
                    let videoPath = self.fileInDocumentsDirectory(fileName: videoName)
                    if let url = videoPath {
                        do {
                            // Remove video data from documents directory.
                            try FileManager.default.removeItem(at: url)
                            // Delete video item from the database.
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
        // Get the video item at the corresponding index.
        let video = savedVideos[indexPath.row]
        // Set the cells duration label.
        cell.durationLabel.text = "\(video.duration ?? "")"
        // Set the cells tag label.
        cell.tagLabel.text = video.tag
        // Get the video items file name.
        if let fileName = video.videoName {
            // Retrieve the documents directory and append the file name to the URL.
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
        // Set the number of cells per row to calculate size.
        let cellsPerRow: CGFloat = 3
        // Calculate the cell size based on collection view width.
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

