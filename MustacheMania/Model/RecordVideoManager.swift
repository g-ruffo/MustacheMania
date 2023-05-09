//
//  RecordVideoManager.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-08.
//

import Foundation

struct RecordVideoManager {
    
    func getTimestampFromSeconds(secondsDouble: Double) -> String {
        let secondsInt = Int(secondsDouble)
            let seconds = secondsInt % 60
            let minutes = (secondsInt / 60) % 60
            let hours   = secondsInt / 3600
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
}
