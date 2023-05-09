//
//  CoreDataService.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit
import CoreData

protocol CoreDataServiceDelegate {
    func videosHaveLoaded(_ coreDataService: CoreDataService, loadedVideos: [RecordedVideoItem])
}
extension CoreDataServiceDelegate {
    func videosHaveLoaded(_ coreDataService: CoreDataService, loadedVideos: [RecordedVideoItem]) {}
}
class CoreDataService {
    private var savedVideos: [RecordedVideoItem] = [] {
        didSet { delegate?.videosHaveLoaded(self, loadedVideos: savedVideos)}
    }
    private let databaseContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var delegate: CoreDataServiceDelegate?
    
    //MARK: - Save Method
    func saveToDatabase() {
        do {
            try databaseContext.save()
        } catch {
            print("Error saving files to core data = \(error)")
        }
    }
    
    //MARK: - Create Video Method
    func createVideo(tag: String, duration: String, fileName: String) {
        let video = RecordedVideoItem(context: databaseContext)
        video.tag = tag
        video.duration = duration
        video.videoName = fileName
        saveToDatabase()
    }
    
    //MARK: - Get Videos Method
    func loadVideosFromDatabase() {
        let request: NSFetchRequest<RecordedVideoItem> = RecordedVideoItem.fetchRequest()
        do{
            savedVideos = try databaseContext.fetch(request)
        } catch {
            print("Error loading files from core data = \(error)")
        }
    }
    //MARK: - Create Update Method
    func updateVideo(newTag: String, atIndex index: Int) {
        let video = savedVideos[index]
        video.tag = newTag
        saveToDatabase()
        delegate?.videosHaveLoaded(self, loadedVideos: savedVideos)
    }
    
    //MARK: - Delete Video Method
    func deleteVideo(atIndex index: Int) {
        databaseContext.delete(savedVideos[index])
        saveToDatabase()
        loadVideosFromDatabase()
    }
}
