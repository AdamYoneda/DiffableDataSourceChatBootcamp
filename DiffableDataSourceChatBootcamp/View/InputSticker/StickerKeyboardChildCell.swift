//
//  StickerKeyboardChildCell.swift
//  StickerKeyboard
//
//  Created by Adam Yoneda on 2023/07/21.
//

import UIKit

final class StickerKeyboardChildCell: UICollectionViewCell {
    
    static let nib = UINib(nibName: "StickerKeyboardChildCell", bundle: nil)
    static let cellIdentifier = "StickerKeyboardChildCell"

    @IBOutlet weak var stickerImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        stickerImageView.contentMode = .scaleAspectFit
    }

    func configure(urlString: String) {
        stickerImageView.setImage(withURLString: urlString)
    }
    
    func configure(image: UIImage) {
        stickerImageView.image = image
    }
}
