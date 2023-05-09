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
    
    //MARK: - Save Methods
    func saveToDatabase() {
        do {
            try databaseContext.save()
        } catch {
            print("Error saving files to core data = \(error)")
        }
    }
    
    //MARK: - Create Video Methods
    func createUpdateVideo(tag: String, duration: String, fileName: String) {
        let video = RecordedVideoItem(context: databaseContext)
        video.tag = tag
        video.duration = duration
        video.videoName = fileName
        saveToDatabase()
    }
    
    //MARK: - Get Video Methods
    func loadVideosFromDatabase() {
        let request: NSFetchRequest<RecordedVideoItem> = RecordedVideoItem.fetchRequest()
        do{
            savedVideos = try databaseContext.fetch(request)
        } catch {
            print("Error loading files from core data = \(error)")
        }
    }
}
