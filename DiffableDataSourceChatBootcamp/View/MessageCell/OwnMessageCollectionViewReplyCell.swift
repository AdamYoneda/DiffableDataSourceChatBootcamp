//
//  OwnMessageCollectionViewReplyCell.swift
//  
//
//  Created by Apple on 2023/08/23.
//

import UIKit

protocol OwnMessageCollectionViewReplyCellDelegate: AnyObject {
    func longTapReplyCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool)
    func tapReplyMessageView(messageId: String, replyMessageId: String)
}

final class OwnMessageCollectionViewReplyCell: UICollectionViewCell, UIGestureRecognizerDelegate {

    @IBOutlet weak var messageStackView: UIStackView!
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var replyMessageTextView: UITextView!
    
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    
    //MARK: NSConstraints
    // リアクションなし
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageStackViewBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var messageStackViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    static let nib = UINib(nibName: "OwnMessageCollectionViewReplyCell", bundle: nil)
    static let nibName = "OwnMessageCollectionViewReplyCell"
    static let cellIdentifier = "OwnMessageCollectionViewReplyCell"
    
    weak var delegate: OwnMessageCollectionViewReplyCellDelegate?
    private var indexPath: IndexPath?
    private var messageId: String?
    private var replyMessageId: String?
    
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
    
    private let basePinkColor = UIColor(red: 244/255, green: 219/255, blue: 219/255, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUpView()
        addLongTapGesture()
        addTapGesture()
    }
    
    private func setUpView() {
        
        messageView.clipsToBounds = true
        messageView.customTop()
        
        replyView.clipsToBounds = true
        replyView.customBottom()
        
        messageStackView.clipsToBounds = true
        messageStackView.layer.cornerRadius = 8
    }
    
    private func addLongTapGesture() {
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapReplyCell(_:)))
        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.delegate = self
        messageStackView.addGestureRecognizer(longTapGesture)
    }
    
    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMessageCell(_:)))
        messageView.addGestureRecognizer(tapGesture)
    }
    
    private func setAttributedText(_ text: String) -> NSAttributedString {
        let attributedText = NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1),
        ])
        
        return attributedText
    }
    
    func configure(_ message: Message, delegate: OwnMessageCollectionViewReplyCellDelegate, indexPath: IndexPath) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        self.messageId = message.document_id
        self.replyMessageId = message.reply_message_id
        
        let messageText = message.text
        let messageRead = message.read
        let messageSender = message.creator
        
        let loginUser = GlobalVar.shared.loginUser
        let loginUID = loginUser?.uid ?? ""
        let isOwnMessage = (messageSender == loginUID)
        
        messageStackView.backgroundColor = (isOwnMessage ? .accentColor : .systemGray6)
        messageView.backgroundColor = (isOwnMessage ? .accentColor : .systemGray6)
        replyView.backgroundColor = (isOwnMessage ? .accentColor : .systemGray6)
        nickNameLabel.textColor = (isOwnMessage ? .white : .fontColor)
        messageTextLabel.textColor = (isOwnMessage ? .white : .fontColor)
        replyMessageTextView.textColor = (isOwnMessage ? .white : .fontColor)
        
        replyMessageTextView.attributedText = setAttributedText(messageText)
        replyMessageTextView.font = .systemFont(ofSize: 15)
        
        if replyMessageTextView.dataDetectorTypes == .link {
            replyMessageTextView.tintColor = .link
        }
        
        readLabel.isHidden = (messageRead ? false : true)
        
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
            messageStackViewBottomConstraint.isActive = true
            messageStackViewBottomConstraintWithReaction.isActive = false
        } else {
            reactionLabel.isHidden = false
            reactionLabel.text = message.reactionEmoji
            dateLabelBottomConstraint.isActive = false
            dateLabelBottomConstraintWithReaction.isActive = true
            messageStackViewBottomConstraint.isActive = false
            messageStackViewBottomConstraintWithReaction.isActive = true
        }
        
        guard let replyMessageText = message.reply_message_text else { return }
        guard let replyMessageSender = message.reply_message_creator else { return }
        guard let replyMessagePhotos = message.reply_message_image_urls else { return }
        guard let replyMessageType = message.reply_message_type else { return }
            
        let loginNickName = loginUser?.nick_name ?? ""
        let loginProfileIconImg = loginUser?.profile_icon_img ?? ""
            
        var replyMessageProfileIconImg = ""
        var replyMessageNickName = ""
            
        let isLoginUser = (replyMessageSender == loginUID)
        if isLoginUser {
            
            replyMessageProfileIconImg = loginProfileIconImg
            replyMessageNickName = loginNickName
            
        } else {
                
            let room = loginUser?.rooms.first(where: { $0.members.contains(replyMessageSender) })
            let partnerUser = room?.partnerUser
            let partnerNickName = room?.partnerNickname ?? partnerUser?.nick_name ?? ""
            let partnerProfileIconImg = partnerUser?.profile_icon_img ?? ""
                
            replyMessageProfileIconImg = partnerProfileIconImg
            replyMessageNickName = partnerNickName
        }
            
        iconImageView.clipsToBounds = true
        iconImageView.rounded()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.setBorder()
        iconImageView.setImage(withURLString: replyMessageProfileIconImg)
            

        nickNameLabel.text = replyMessageNickName
        nickNameLabel.font = .boldSystemFont(ofSize: 12)
        nickNameLabel.numberOfLines = 1
        nickNameLabel.lineBreakMode = .byTruncatingTail
        
        messageTextLabel.font = .systemFont(ofSize: 12)
        messageTextLabel.numberOfLines = 2
        messageTextLabel.lineBreakMode = .byTruncatingTail
        
        switch replyMessageType {
        case .image:
            messageTextLabel.text = "画像"
            break
        case .sticker:
            messageTextLabel.text = "スタンプ"
            break
        default:
            messageTextLabel.text = replyMessageText
            break
        }
        
        messageImageView.isHidden = true
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 8
        guard let replyMessagePhoto = replyMessagePhotos.first else { return }
        messageImageView.isHidden = false
        messageImageView.setImage(withURLString: replyMessagePhoto)
    }
    
    @objc private func longTapReplyCell(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed, let _indexPath = indexPath else { return }
        delegate?.longTapReplyCell(indexPath: _indexPath, rect: messageStackView.frame, type: .reply, isOwn: true)
    }
    
    @objc private func tapMessageCell(_ sender: UITapGestureRecognizer) {
        guard let messageId, let replyMessageId, !replyMessageId.isEmpty else { return }
        delegate?.tapReplyMessageView(messageId: messageId, replyMessageId: replyMessageId)
    }
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
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
}
