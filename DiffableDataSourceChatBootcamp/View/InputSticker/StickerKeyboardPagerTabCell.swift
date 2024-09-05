//
//  StickerKeyboardPagerTabCell.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/07/26.
//

import UIKit

final class StickerKeyboardPagerTabCell: UICollectionViewCell {
    
    static let nib = UINib(nibName: "StickerKeyboardPagerTabCell", bundle: nil)
    static let cellIdentifier = "StickerKeyboardPagerTabCell"
    
    @IBOutlet private weak var stickerIconBackgroundView: UIView!
    @IBOutlet private weak var stickerIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .white
        stickerIconBackgroundView.layer.cornerRadius = 5
        stickerIconImageView.contentMode = .scaleAspectFit
    }

    func tabIsSelected(_ isSelected: Bool) {
        stickerIconBackgroundView.backgroundColor = isSelected ? UIColor.systemGray6 : UIColor.white
    }
    
    func setIconImage(image: UIImage) {
        stickerIconImageView.image = image
    }
    
    func setIconImage(urlString: String) {
        stickerIconImageView.setImage(withURLString: urlString)
    }
}
