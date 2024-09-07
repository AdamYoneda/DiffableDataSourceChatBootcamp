//
//  OwnMessageCollectionViewCell.swift
//  Tauch
//
//  Created by Apple on 2023/07/26.
//

import UIKit

protocol OwnMessageCollectionViewCellDelegate: AnyObject {
    func longTapTextCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool)
}

final class OwnMessageCollectionViewCell: UICollectionViewCell, UIGestureRecognizerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    @IBOutlet weak var heartIcon: UIImageView!
    
    //MARK: NSConstraints
    // リアクションなし
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var textViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    static let nib = UINib(nibName: "OwnMessageCollectionViewCell", bundle: nil)
    static let nibName = "OwnMessageCollectionViewCell"
    static let cellIdentifier = "OwnMessageCollectionViewCell"
    
    weak var delegate: OwnMessageCollectionViewCellDelegate?
    private var indexPath: IndexPath?
    
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
    }
    
    private func setUpTapGesture() {
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapMessageCell(_:)))
        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.delegate = self
        textView.addGestureRecognizer(longTapGesture)
    }
    
    private func setAttributedText(_ text: String) -> NSAttributedString {
        let attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white,
        ])
        
        return attributedText
    }
    
    func configure(_ user: User, message: Message, roomStatus: RoomStatus?, delegate: OwnMessageCollectionViewCellDelegate, indexPath: IndexPath) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        
        textView.textContainer.lineFragmentPadding = 10
        textView.attributedText = setAttributedText(message.text)
        
        if textView.dataDetectorTypes == .link {
            textView.tintColor = .link
        }
        
        if message.read {
            readLabel.isHidden = false
        } else {
            readLabel.isHidden = true
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
            textView.backgroundColor = .accentColor
            textView.textColor = .white
            heartIcon.isHidden = true
            break
        case .sBest, .ssBest, .sssBest:
            if roomStatus == .sBest {
                heartIcon.isHidden = true
            } else {
                heartIcon.isHidden = false
            }
            textView.backgroundColor = .white
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
    
    @objc private func longTapMessageCell(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed, let _indexPath = indexPath else { return }
        delegate?.longTapTextCell(indexPath: _indexPath, rect: textView.frame, type: .text, isOwn: true)
    }
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
}

