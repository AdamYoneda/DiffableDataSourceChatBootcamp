//
//  OwnMessageCollectionViewReplyStickerCell.swift
//  
//
//  Created by Adam Yoneda on 2023/10/16.
//

import UIKit

protocol OwnMessageCollectionViewReplyStickerCellDelegate: AnyObject {
    func onOwnStickerTapped(cell: OwnMessageCollectionViewReplyStickerCell, stickerUrl: String)
    func longTapStickerCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool)
    func tapReplyMessageView(messageId: String, replyMessageId: String)
}

final class OwnMessageCollectionViewReplyStickerCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    static let nib = UINib(nibName: "OwnMessageCollectionViewReplyStickerCell", bundle: nil)
    
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var stickerView: UIImageView!
    @IBOutlet weak var readLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var reactionLabel: UILabel!
    // MARK: NSConstraints
    // リアクションなし
    @IBOutlet weak var dateLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stickerViewBottomConstraint: NSLayoutConstraint!
    // リアクションあり
    @IBOutlet weak var dateLabelBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var stickerViewBottomConstraintWithReaction: NSLayoutConstraint!
    @IBOutlet weak var reactionBottomConstraint: NSLayoutConstraint!
    
    weak private var delegate: OwnMessageCollectionViewReplyStickerCellDelegate?
    private var indexPath: IndexPath?
    private var stickerUrl: String?
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
        
        setUpTapGesture()
        setStickerSize()
        setupViews()
    }
    
    private func setUpTapGesture() {
        stickerView.isUserInteractionEnabled = true
        
        let stickerViewTapGesgure = UITapGestureRecognizer(target: self, action: #selector(stickerTapped(_:)))
        stickerView.addGestureRecognizer(stickerViewTapGesgure)
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTapStickerView(_:)))
        longTapGesture.minimumPressDuration = 0.3
        longTapGesture.delegate = self
        stickerView.addGestureRecognizer(longTapGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMessageCell(_:)))
        messageView.addGestureRecognizer(tapGesture)
    }
    
    private func setStickerSize() {
        let screenWidth = UIScreen.main.bounds.width
        let constant = screenWidth * 0.35
        stickerView.widthAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    private func setupViews() {
        messageView.clipsToBounds = true
        messageView.layer.cornerRadius = 8
        
        iconImageView.clipsToBounds = true
        iconImageView.rounded()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.setBorder()
        
        nickNameLabel.font = .boldSystemFont(ofSize: 12)
        nickNameLabel.numberOfLines = 1
        nickNameLabel.lineBreakMode = .byTruncatingTail
        
        messageTextLabel.font = .systemFont(ofSize: 12)
        messageTextLabel.numberOfLines = 2
        messageTextLabel.lineBreakMode = .byTruncatingTail
        
        messageImageView.clipsToBounds = true
        messageImageView.layer.cornerRadius = 8
    }
    
    @objc private func stickerTapped(_ sender: UITapGestureRecognizer) {
        if let _stickerUrl = self.stickerUrl {
            delegate?.onOwnStickerTapped(cell: self, stickerUrl: _stickerUrl)
        }
    }
    
    @objc private func longTapStickerView(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began, sender.state != .changed, let _indexPath = indexPath else { return }
        delegate?.longTapStickerCell(indexPath: _indexPath, rect: stickerView.frame, type: .sticker, isOwn: true)
    }
    
    @objc private func tapMessageCell(_ sender: UITapGestureRecognizer) {
        guard let messageId, let replyMessageId, !replyMessageId.isEmpty else { return }
        delegate?.tapReplyMessageView(messageId: messageId, replyMessageId: replyMessageId)
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
    
    // タップイベントの干渉の際に必要
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.shouldRequireFailure(of: otherGestureRecognizer)
    }
    
    func configure(_ user: User, message: Message, room: Room?, delegate: OwnMessageCollectionViewReplyStickerCellDelegate, indexPath: IndexPath) {
        
        self.delegate = delegate
        self.indexPath = indexPath
        self.messageId = message.document_id
        self.replyMessageId = message.reply_message_id
        
        // スタンプ等基本の部分
        guard let stickerUrl = message.photos.first else { return }
        stickerView.setImage(withURLString: stickerUrl)
        
        readLabel.isHidden = !message.read
        
        let date = message.updated_at.dateValue()
        if Calendar.current.isDateInToday(date) {
            dateLabel.text = elaspedTime.string(from: message.updated_at.dateValue())
        } else if Calendar.current.isDateInYesterday(date) {
            dateLabel.text = "昨日 " + elaspedTime.string(from: message.updated_at.dateValue())
        } else {
            dateLabel.text = pastTime.string(from: message.updated_at.dateValue())
        }
        
        if let sticker = message.sticker {
            stickerView.image = sticker
        } else if let stickerURL = message.photos.first {
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
        // リプライ部分
        let loginUser = GlobalVar.shared.loginUser
        guard let replyMessageText = message.reply_message_text,
              let replyMessageSender = message.reply_message_creator,
              let replyMessagePhotos = message.reply_message_image_urls,
              let replyMessageType = message.reply_message_type,
              let loginNickName = loginUser?.nick_name,
              let loginProfileIconImg = loginUser?.profile_icon_img,
              let partnerUser = room?.partnerUser else { return }
        
        let replyIsOwnMessage = (replyMessageSender == loginUser?.uid)
        let replyMessageProfileIconImg = replyIsOwnMessage ? loginProfileIconImg : partnerUser.profile_icon_img
        let replyMessageNickname = replyIsOwnMessage ? loginNickName : room?.partnerNickname ?? partnerUser.nick_name
        
        iconImageView.setImage(withURLString: replyMessageProfileIconImg)
        nickNameLabel.text = replyMessageNickname
        
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
        
        if let replyMessagePhoto = replyMessagePhotos.first {
            messageImageView.isHidden = false
            messageImageView.setImage(withURLString: replyMessagePhoto)
        } else {
            messageImageView.isHidden = true
        }
        
        let isOwnMessage = message.creator == loginUser?.uid
        messageView.backgroundColor = (isOwnMessage ? .accentColor : .systemGray6)
        nickNameLabel.textColor = (isOwnMessage ? .white : .fontColor)
        messageTextLabel.textColor = (isOwnMessage ? .white : .fontColor)
    }
}
