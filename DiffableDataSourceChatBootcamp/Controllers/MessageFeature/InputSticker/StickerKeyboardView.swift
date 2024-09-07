//
//  StickerKeyboardView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/07/21.
//

import UIKit

protocol StickerKeyboardViewDelegate: AnyObject {
    func didSelectMessageSticker(_ image: UIImage, identifier: String)
    func didSelectMessageSticker(_ urlString: String)
}

final class StickerKeyboardView: UIView {

    @IBOutlet private weak var stickerCollectionView: UICollectionView!
    @IBOutlet weak var pagerTabCollectionView: UICollectionView!
    
    weak var delegate: StickerKeyboardViewDelegate?
    private var currentIndex: Int = 0 {
        didSet {
            if oldValue != currentIndex {
                pagerTabCollectionView.reloadData()
            }
        }
    }
    
    var stickers: [[String]] = []
    
    private let defaultStickers = GlobalVar.shared.defaultStickers
    
    //MARK: init

    internal init() {
        super.init(frame: .zero)
        loadNib()
        configureStickerCollectionView()
        configurePagerTabCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: configure

    private func loadNib() {
        guard let view = UINib(nibName: "StickerKeyboardView", bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("StickerKeyboardView init() failed.")
        }
        view.frame = bounds
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    private func configureStickerCollectionView() {
        stickerCollectionView.delegate = self
        stickerCollectionView.dataSource = self
        
        stickerCollectionView.isPagingEnabled = true
        stickerCollectionView.isScrollEnabled = true
        stickerCollectionView.showsHorizontalScrollIndicator = false
        
        stickerCollectionView.backgroundColor = .white
        
        stickerCollectionView.register(StickerKeyboardViewCell.nib, forCellWithReuseIdentifier: StickerKeyboardViewCell.cellIdentifier)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        stickerCollectionView.collectionViewLayout = layout
    }
    
    private func configurePagerTabCollectionView() {
        pagerTabCollectionView.delegate = self
        pagerTabCollectionView.dataSource = self
        
        pagerTabCollectionView.isPagingEnabled = false
        pagerTabCollectionView.isScrollEnabled = true
        pagerTabCollectionView.showsHorizontalScrollIndicator = false
        
        pagerTabCollectionView.backgroundColor = .white
        
        pagerTabCollectionView.register(StickerKeyboardPagerTabCell.nib, forCellWithReuseIdentifier: StickerKeyboardPagerTabCell.cellIdentifier)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 5, left: 30, bottom: 5, right: 0)
        pagerTabCollectionView.collectionViewLayout = layout
    }
}


//MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension StickerKeyboardView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfSections section: Int) -> Int {
            return 1
        }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case stickerCollectionView:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerKeyboardViewCell.cellIdentifier, for: indexPath) as? StickerKeyboardViewCell else { fatalError("StickerKeyboardView - dequeReusableCell error") }
            if indexPath.row < stickers.count {
                if let stickers = self.stickers[safe: indexPath.row] {
                    cell.stickers = stickers
                    cell.delegate = self
                    cell.defaultStickers = nil
                }
            } else {
                cell.defaultStickers = self.defaultStickers
                cell.delegate = self
            }
            return cell
            
        case pagerTabCollectionView:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerKeyboardPagerTabCell.cellIdentifier, for: indexPath) as? StickerKeyboardPagerTabCell else { fatalError("StickerKeyboardView - dequeReusableCell error") }
            // 画像をセット
            if indexPath.row < stickers.count {
                if let stickerUrl = self.stickers[safe: indexPath.section]?.first {
                    cell.setIconImage(urlString: stickerUrl)
                }
            } else {
                if let firstImage = defaultStickers.first {
                    cell.setIconImage(image: firstImage)
                }
            }
            // currentIndexによって判定
            if indexPath.row == currentIndex {
                cell.tabIsSelected(true)
            } else {
                cell.tabIsSelected(false)
            }
            return cell
            
        default:
            fatalError("StickerKeyboardView - UICollectionViewのswitchでエラー発生")
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch collectionView {
        case stickerCollectionView:
            return CGSize(width: stickerCollectionView.frame.width, height: stickerCollectionView.frame.height)
        case pagerTabCollectionView:
            return CGSize(width: pagerTabCollectionView.frame.height, height: pagerTabCollectionView.frame.height)
        default:
            fatalError("StickerKeyboardView - UICollectionViewのswitchでエラー発生")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == pagerTabCollectionView {
            currentIndex = indexPath.row
            stickerCollectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == stickerCollectionView {
            currentIndex = Int(scrollView.contentOffset.x / stickerCollectionView.frame.size.width)
        }
    }
}

extension StickerKeyboardView: StickerKeyboardViewCellDelegate {
    func didSelectMessageSticker(_ image: UIImage, identifier: String) {
        self.delegate?.didSelectMessageSticker(image, identifier: identifier)
    }
    
    func didSelectMessageSticker(_ urlString: String) {
        self.delegate?.didSelectMessageSticker(urlString)
    }
}
