//
//  StickerKeyboardViewCell.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/07/24.
//

import UIKit

protocol StickerKeyboardViewCellDelegate: AnyObject {
    func didSelectMessageSticker(_ image: UIImage, identifier: String)
    func didSelectMessageSticker(_ urlString: String)
}

final class StickerKeyboardViewCell: UICollectionViewCell {
    
    static let nib = UINib(nibName: "StickerKeyboardViewCell", bundle: nil)
    static let cellIdentifier = "StickerKeyboardViewCell"
    
    @IBOutlet weak var childCollectionView: UICollectionView!
    
    var stickers: [String] = [] {
        didSet {
            childCollectionView.reloadData()
        }
    }
    var defaultStickers: [UIImage]? {
        didSet {
            childCollectionView.reloadData()
        }
    }
    
    weak var delegate: StickerKeyboardViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureCollectionView()
    }
    
    private func configureCollectionView() {
        childCollectionView.delegate = self
        childCollectionView.dataSource = self
        
        childCollectionView.backgroundColor = .white
        
        childCollectionView.register(StickerKeyboardChildCell.nib, forCellWithReuseIdentifier: StickerKeyboardChildCell.cellIdentifier)

        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 15, bottom: 15, right: 15)
        layout.minimumInteritemSpacing = 10.0
        layout.minimumLineSpacing = 5.0
        layout.scrollDirection = .vertical
        childCollectionView.collectionViewLayout = layout
    }
}


//MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension StickerKeyboardViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfSections section: Int) -> Int {
            return 1
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if defaultStickers == nil {
            return stickers.count
        } else {
            return defaultStickers!.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerKeyboardChildCell.cellIdentifier, for: indexPath) as? StickerKeyboardChildCell else { fatalError("StickerKeyboardViewCell - dequeReusableCell error") }
        if defaultStickers == nil{
            if let stickerUrl = stickers[safe: indexPath.row] {
                cell.configure(urlString: stickerUrl)
            }
        } else {
            if let stickerImage = defaultStickers?[safe: indexPath.row] as? UIImage{
                cell.configure(image: stickerImage)
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSideLength = (childCollectionView.frame.width - (10.0 * 3) - (15.0 * 2)) / 4
        return CGSize(width: cellSideLength, height: cellSideLength)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if defaultStickers == nil {
            if let selectedUrlString = stickers[safe: indexPath.row] {
                delegate?.didSelectMessageSticker(selectedUrlString)
            }
            
        } else {
            if let selectedImage = defaultStickers![safe: indexPath.row], let identifier = GlobalVar.shared.defaultStickerIdentifier[safe: indexPath.row] {
                delegate?.didSelectMessageSticker(selectedImage, identifier: identifier)
            }
        }
    }
}

