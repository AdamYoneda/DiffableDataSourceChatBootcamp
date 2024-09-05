//
//  UnreadMessageCollectionViewCell.swift
//  Tauch
//
//  Created by Apple on 2023/09/22.
//

import UIKit

class UnreadMessageCollectionViewCell: UICollectionViewCell {
    
    static let nib = UINib(nibName: "UnreadMessageCollectionViewCell", bundle: nil)
    static let nibName = "UnreadMessageCollectionViewCell"
    static let cellIdentifier = "UnreadMessageCollectionViewCell"
    
    @IBOutlet weak var backgroundBaseView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupView()
    }
    
    private func setupView() {
        contentView.backgroundColor = .white
        backgroundBaseView.backgroundColor = .black.withAlphaComponent(0.3)
        backgroundBaseView.clipsToBounds = true
        backgroundBaseView.layer.cornerRadius = backgroundBaseView.frame.height / 2
        
        self.contentView.backgroundColor = .clear
    }
}
