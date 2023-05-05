//
//  RecordVideoViewController.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit

class RecordVideoViewController: UIViewController {
    private var coreDataService = CoreDataService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set CoreDataService delegate.
        coreDataService.delegate = self

    }
    
}

// MARK: - CoreDataServiceDelegate
extension RecordVideoViewController: CoreDataServiceDelegate {

}
