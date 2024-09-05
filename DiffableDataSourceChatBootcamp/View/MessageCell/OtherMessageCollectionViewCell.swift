//
//  OtherMessageCollectionViewCell.swift
//  Tauch
//
//  Created by Apple on 2023/07/26.
//

import UIKit

protocol OtherMessageCollectionViewCellDelegate: AnyObject {
    func onProfileIconTapped(cell: OtherMessageCollectionViewCell, user: User)
    func longTapTextCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool)
}

final class OtherMessageCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    // リアクションなし
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var textViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    static let nib = UINib(nibName: "OtherMessageCollectionViewCell", bundle: nil)
    static let nibName = "OtherMessageCollectionViewCell"
    static let cellIdentifier = "OtherMessageCollectionViewCell"
    
    weak var delegate: OtherMessageCollectionViewCellDelegate?
    private var indexPath: IndexPath?
    
    var user: User?
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()

        setUpTapGesture()
        setUpImageView()
    }
    
    private func setUpTapGesture() {
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onIconImageViewTapped(_:))
        )
        iconImageView.addGestureRecognizer(tapGesture)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapMessageCell(_:)))
        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.delegate = self
        textView.addGestureRecognizer(longTapGesture)
    }

    private func setAttributedText(_ text: String) -> NSAttributedString {
        let attributedText = NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1),
        ])
        
        return attributedText
    }
    
    private func setUpImageView() {
        iconImageView.clipsToBounds = true
        iconImageView.rounded()
        iconImageView.contentMode = .scaleAspectFill
        let iconImageViewTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onIconImageViewTapped(_:))
        )
        iconImageView.addGestureRecognizer(iconImageViewTapGesture)
    }
    
    func configure(_ user: User, message: Message, roomStatus: RoomStatus?, delegate: OtherMessageCollectionViewCellDelegate, indexPath: IndexPath) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        self.user = user
        
        let iconImg = user.profile_icon_img
        iconImageView.setImage(withURLString: iconImg)
        
        if message.text.isEmpty {
            textView.isHidden = true
        } else {
            textView.isHidden = false
            textView.textContainer.lineFragmentPadding = 10
            textView.attributedText = setAttributedText(message.text)
        }
        
        if textView.dataDetectorTypes == .link {
            textView.tintColor = .link
        }
        
        let date = message.updated_at.dateValue()
        if Calendar.current.isDateInToday(date) {
            dateLabel.text = elaspedTime.string(from: message.updated_at.dateValue())
        } else if Calendar.current.isDateInYesterday(date) {
            dateLabel.text = "昨日 " + elaspedTime.string(from: message.updated_at.dateValue())
        } else {
            dateLabel.text = pastTime.string(from: message.updated_at.dateValue())
        }
        
        if message.reactionEmoji.isEmpty {
            reactionLabel.isHidden = true
            dateLabelBottomConstraint.isActive = true
            dateLabelBottomConstraintWithReaction.isActive = false
            textViewBottomConstraint.isActive = true
            textViewBottomConstraintWithReaction.isActive = false
        } else {
            reactionLabel.isHidden = false
            reactionLabel.text = message.reactionEmoji
            dateLabelBottomConstraint.isActive = false
            dateLabelBottomConstraintWithReaction.isActive = true
            textViewBottomConstraint.isActive = false
            textViewBottomConstraintWithReaction.isActive = true
        }
        
        switch roomStatus {
        case .normal:
            textView.backgroundColor = .systemGray6
            textView.textColor = .fontColor
            break
        case .sBest, .ssBest, .sssBest:
            textView.backgroundColor = UIColor.MessageColor.cellPink
            textView.textColor = UIColor.MessageColor.heavyPink
            textView.layer.borderColor = UIColor.MessageColor.standardPink.cgColor
            textView.layer.borderWidth = 1.5
            break
        case .none:
            break
        }
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
    
    @objc private func onIconImageViewTapped(_ sender: UITapGestureRecognizer) {
        if let user = user {
            delegate?.onProfileIconTapped(cell: self, user: user)
        }
    }
    
    @objc private func longTapMessageCell(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed, let _indexPath = indexPath else { return }
        delegate?.longTapTextCell(indexPath: _indexPath, rect: textView.frame, type: .text, isOwn: false)
    }
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
}
