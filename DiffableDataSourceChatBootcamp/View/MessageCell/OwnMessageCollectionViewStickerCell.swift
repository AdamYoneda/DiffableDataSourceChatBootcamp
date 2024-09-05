//
//  OwnMessageCollectionViewStickerCell.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/31.
//

import UIKit

protocol OwnMessageCollectionViewStickerCellDelegate: AnyObject {
    func onOwnStickerTapped(cell: OwnMessageCollectionViewStickerCell, stickerUrl: String)
    func longTapStickerCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool)
}

final class OwnMessageCollectionViewStickerCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var stickerView: UIImageView!
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var datelabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    @IBOutlet weak var stickerWidth: NSLayoutConstraint!
    @IBOutlet weak var stickerHeight: NSLayoutConstraint!
    
    //MARK: NSConstraints
    // リアクションなし
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stickerViewBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var stickerViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    static let nib = UINib(nibName: "OwnMessageCollectionViewStickerCell", bundle: nil)
    static let nibName = "OwnMessageCollectionViewStickerCell"
    static let cellIdentifier = "OwnMessageCollectionViewStickerCell"
    
    weak private var delegate: OwnMessageCollectionViewStickerCellDelegate?
    private var indexPath: IndexPath?
    
    var stickerUrl: String?
    
    var elaspedTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var pastTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy/MM/dd/ HH:mm"
        return formatter
    }()
    
    //MARK: Setup
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUpTapGesture()
        setStickerSize()
    }
    
    private func setUpTapGesture() {
        let stickerViewTapGesgure = UITapGestureRecognizer(target: self, action: #selector(stickerTapped(_:)))
        stickerView.addGestureRecognizer(stickerViewTapGesgure)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapMessageCell(_:)))
        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.delegate = self
        stickerView.addGestureRecognizer(longTapGesture)
    }
    
    private func setStickerSize() {
        let screenWidth = UIScreen.main.bounds.width
        let constant = screenWidth * 0.35
        stickerWidth.constant = constant
        stickerHeight.constant = constant
    }
    
    @objc private func stickerTapped(_ sender: UITapGestureRecognizer) {
        if let _stickerUrl = self.stickerUrl {
            delegate?.onOwnStickerTapped(cell: self, stickerUrl: _stickerUrl)
        }
    }
    
    //MARK: Public methods
    
    func configure(_ user: User, message: Message, delegate: OwnMessageCollectionViewStickerCellDelegate, indexPath: IndexPath) {
        
        readLabel.isHidden = !message.read
        
        let date = message.updated_at.dateValue()
        if Calendar.current.isDateInToday(date) {
            datelabel.text = elaspedTime.string(from: message.updated_at.dateValue())
        } else if Calendar.current.isDateInYesterday(date) {
            datelabel.text = "昨日 " + elaspedTime.string(from: message.updated_at.dateValue())
        } else {
            datelabel.text = pastTime.string(from: message.updated_at.dateValue())
        }
        
        if let sticker = message.sticker {
            // 1. GlobalVarからUIImageを使用
            stickerView.image = sticker
        } else if let sticker = UIImage(named: message.stickerIdentifier) {
            // 2. identifierからインスタンス化
            stickerView.image = sticker
        } else if let stickerURL = message.photos.first {
            // 3. URLからダウンロード
            self.stickerUrl = stickerURL
            stickerView.setImage(withURLString: stickerURL)
        }
        
        if message.reactionEmoji.isEmpty {
            reactionLabel.isHidden = true
            dateLabelBottomConstraint.isActive = true
            dateLabelBottomConstraintWithReaction.isActive = false
            stickerViewBottomConstraint.isActive = true
            stickerViewBottomConstraintWithReaction.isActive = false
        } else {
            reactionLabel.isHidden = false
            reactionLabel.text = message.reactionEmoji
            dateLabelBottomConstraint.isActive = false
            dateLabelBottomConstraintWithReaction.isActive = true
            stickerViewBottomConstraint.isActive = false
            stickerViewBottomConstraintWithReaction.isActive = true
        }
        
        self.delegate = delegate
        self.indexPath = indexPath
    }
    
    func animateReactionLabel(completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.reactionBottomConstraint.constant += 50
            self?.layoutIfNeeded()
            self?.reactionLabel.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.5, animations: {
                self?.reactionBottomConstraint.constant = 0
                self?.layoutIfNeeded()
                self?.reactionLabel.transform = .identity
            }, completion: completion)
        }
    }
    
    @objc private func longTapMessageCell(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed, let _indexPath = indexPath else { return }
        delegate?.longTapStickerCell(indexPath: _indexPath, rect: stickerView.frame, type: .sticker, isOwn: true)
    }
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
}
