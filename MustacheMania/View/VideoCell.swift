//
//  VideoCell.swift
//  MustacheMania
//
//  Created by Grayson Ruffo on 2023-05-04.
//

import UIKit

class VideoCell: UICollectionViewCell {

    @IBOutlet weak var videoPreviewImage: UIImageView!
    @IBOutlet weak var durationViewContainer: UIView!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Add corner radius to duration container and cell.
        durationViewContainer.layer.cornerRadius = durationViewContainer.frame.height / 2
        self.layer.cornerRadius = 10
    }
    
    static func nib() -> UINib {
        return UINib(nibName: K.Cell.videoCell, bundle: nil)
    }
}
