//
//  MessageInputView.swift
//
//  Created by Adam Yoneda on 2023/09/02.
//

import UIKit

protocol MessageInputViewStickerDelegate: AnyObject {
    func closeStickerPreview()
    func sendMessageSticker()
}

protocol MessageInputViewReplyDelegate: AnyObject {
    func closeReplyPreview()
}

protocol MessageNoticeViewDelegate: AnyObject {
    func tappedNoticePreview()
}

final class MessageInputView: UIView {
    
    private let previewStackView = UIStackView()
    private let stickerPreviewFrame: CGRect
    private let stickerPreviewCloseButton = UIButton(type: .close)
    private let replyPreviewFrame: CGRect
    private let replyPreviewIconImageView = UIImageView()
    private let replyPreviewNickNameLabel = UILabel()
    private let replyPreviewMessageTextLabel = UILabel()
    private let replyPreviewMessageImageView = UIImageView()
    private let replyPreviewCloseButton = UIButton(type: .close)
    private let REPRY_VIEW_HEIGHT = 70.0
    private let noticePreviewMessageTextLabel = UILabel()
    private let noticePreviewFrame: CGRect
    private let NOTICE_VIEW_HEIGHT = 25.0
    
    let stickerPreview = UIView()
    let stickerPreviewImageView = UIImageView()
    let replyPreview = UIView()
    let noticePreview = UIView()
    
    weak var stickerDelegate: MessageInputViewStickerDelegate?
    weak var replyDelegate: MessageInputViewReplyDelegate?
    weak var noticeDelegate: MessageNoticeViewDelegate?

    private var room: Room?
    
    init() {
        stickerPreviewFrame = .zero
        replyPreviewFrame = .zero
        noticePreviewFrame = .zero
        super.init(frame: .zero)
        
        backgroundColor = .white
        replyPreview.backgroundColor = .white
    }
    
    init(frame: CGRect, replyPreviewFrame: CGRect, stickerPreviewFrame: CGRect, noticePreviewFrame: CGRect, room: Room) {
        
        self.replyPreviewFrame = replyPreviewFrame
        self.stickerPreviewFrame = stickerPreviewFrame
        self.noticePreviewFrame = noticePreviewFrame
        self.room = room
        
        super.init(frame: frame)
        
        configurePreviewStackView()
        configureStickerPreview()
        configureReplyPreview(room: room)
        configureMessageNoticeView()
        
        backgroundColor = .white
        replyPreview.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let stickerPreviewIsShown = (stickerPreview.isHidden == false)
        let stickerPreviewIsClose = (stickerPreviewCloseButton.bounds.contains(stickerPreviewCloseButton.convert(point, from: self)) && stickerPreviewIsShown)
        let stickerPreviewIsImage = (stickerPreviewImageView.bounds.contains(stickerPreviewImageView.convert(point, from: self)) && stickerPreviewIsShown)
        let stickerPreviewIsShow = (stickerPreview.bounds.contains(stickerPreview.convert(point, from: self)) && stickerPreviewIsShown)
        
        let replyPreviewIsShown = (replyPreview.isHidden == false)
        let replyPreviewIsClose = (replyPreviewCloseButton.bounds.contains(replyPreviewCloseButton.convert(point, from: self)) && replyPreviewIsShown)
        let replyPreviewIsShow = (replyPreview.bounds.contains(replyPreview.convert(point, from: self)) && replyPreviewIsShown)
        
        let noticePreviewIsShown = (noticePreview.isHidden == false)
        let noticePreviewIsAppear = (noticePreview.bounds.contains(noticePreview.convert(point, from: self)) && noticePreviewIsShown )
        
        if stickerPreviewIsClose {
            return stickerPreviewCloseButton
        } else if stickerPreviewIsImage {
            return stickerPreviewImageView
        } else if stickerPreviewIsShow {
            return stickerPreview
        } else if replyPreviewIsClose {
            return replyPreviewCloseButton
        } else if replyPreviewIsShow {
            return replyPreview
        } else if noticePreviewIsAppear {
            return noticePreview
        }
        return super.hitTest(point, with: event)
    }
    
    // MARK: - PreviewStackView
    
    private func configurePreviewStackView() {
        previewStackView.backgroundColor = .clear
        previewStackView.axis = .vertical
        previewStackView.distribution = .fillProportionally
        previewStackView.spacing = 0
        previewStackView.alignment = .center
        previewStackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(previewStackView)
        
        let heightConstraint = previewStackView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        heightConstraint.priority = .defaultLow
        
        previewStackView.bottomAnchor.constraint(equalTo: self.topAnchor).isActive = true
        previewStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        previewStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
    
    // MARK: StickerPreview
    private func configureStickerPreview() {
        let screenHeight = UIScreen.main.bounds.size.height
        
        previewStackView.addArrangedSubview(stickerPreview)
        stickerPreview.backgroundColor = .systemGray6.withAlphaComponent(0.8)
        stickerPreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeStickerPreview)))
        stickerPreview.heightAnchor.constraint(equalToConstant: stickerPreviewFrame.height).isActive = true
        stickerPreview.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        stickerPreview.translatesAutoresizingMaskIntoConstraints = false
        
        stickerPreviewImageView.contentMode = .scaleAspectFit
        stickerPreviewImageView.isUserInteractionEnabled = true
        stickerPreviewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sendMessageSticker)))
        stickerPreview.addSubview(stickerPreviewImageView)
        stickerPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        stickerPreviewImageView.widthAnchor.constraint(equalToConstant: screenHeight * 0.15).isActive = true
        stickerPreviewImageView.heightAnchor.constraint(equalToConstant: screenHeight * 0.15).isActive = true
        stickerPreviewImageView.centerXAnchor.constraint(equalTo: stickerPreview.centerXAnchor).isActive = true
        stickerPreviewImageView.centerYAnchor.constraint(equalTo: stickerPreview.centerYAnchor).isActive = true
        
        stickerPreviewCloseButton.addTarget(self, action: #selector(closeStickerPreview), for: .touchUpInside)
        stickerPreviewCloseButton.setTitle("", for: .normal)
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .fontColor
        stickerPreviewCloseButton.configuration = configuration
        stickerPreview.addSubview(stickerPreviewCloseButton)
        stickerPreviewCloseButton.translatesAutoresizingMaskIntoConstraints = false
        stickerPreviewCloseButton.widthAnchor.constraint(equalToConstant: 30.0).isActive = true
        stickerPreviewCloseButton.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
        stickerPreviewCloseButton.topAnchor.constraint(equalTo: stickerPreview.topAnchor, constant: 20.0).isActive = true
        stickerPreviewCloseButton.trailingAnchor.constraint(equalTo: stickerPreview.trailingAnchor, constant: -20.0).isActive = true
    }
    
    /// stickerPreviewの表示・非表示を行う
    func setStickerPreview(active: Bool) {
        if active {
            stickerPreview.isHidden = false
        } else {
            stickerPreview.isHidden = true
        }
    }
    
    @objc private func closeStickerPreview() {
        stickerDelegate?.closeStickerPreview()
    }
    
    @objc private func sendMessageSticker() {
        stickerDelegate?.sendMessageSticker()
    }
    
    // MARK: ReplyPreview
    private func configureReplyPreview(room: Room) {
        
        let screenWidth = UIScreen.main.bounds.size.width
        
        previewStackView.addArrangedSubview(replyPreview)
        // リプライプレビュー 全体
        replyPreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeReplyPreview)))
        replyPreview.translatesAutoresizingMaskIntoConstraints = true
        replyPreview.heightAnchor.constraint(equalToConstant: REPRY_VIEW_HEIGHT).isActive = true
        replyPreview.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        replyPreview.translatesAutoresizingMaskIntoConstraints = false
        let blurView = UIVisualEffectView(frame: replyPreview.frame)
        blurView.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        replyPreview.addSubview(blurView)
        // リプライププレビュー アイコン画像
        replyPreviewIconImageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        replyPreviewIconImageView.clipsToBounds = true
        replyPreviewIconImageView.rounded()
        replyPreviewIconImageView.contentMode = .scaleAspectFill
        replyPreviewIconImageView.isUserInteractionEnabled = true
        replyPreview.addSubview(replyPreviewIconImageView)
        replyPreviewIconImageView.translatesAutoresizingMaskIntoConstraints = false
        replyPreviewIconImageView.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        replyPreviewIconImageView.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        replyPreviewIconImageView.leftAnchor.constraint(equalTo: replyPreview.leftAnchor, constant: 15).isActive = true
        replyPreviewIconImageView.topAnchor.constraint(equalTo: replyPreview.topAnchor, constant: 15).isActive = true
        // リプライププレビュー Closeボタン
        let closeButtonHeight = 30.0
        let closeButtonWidth = 30.0
        let replyPreviewCloseButtonConstant = (screenWidth / 2 - 20.0)
        replyPreviewCloseButton.addTarget(self, action: #selector(closeReplyPreview), for: .touchUpInside)
        replyPreviewCloseButton.setTitle("", for: .normal)
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .lightGray
        replyPreviewCloseButton.configuration = configuration
        replyPreview.addSubview(replyPreviewCloseButton)
        replyPreviewCloseButton.translatesAutoresizingMaskIntoConstraints = false
        replyPreviewCloseButton.widthAnchor.constraint(equalToConstant: closeButtonWidth).isActive = true
        replyPreviewCloseButton.heightAnchor.constraint(equalToConstant: closeButtonHeight).isActive = true
        replyPreviewCloseButton.centerXAnchor.constraint(equalTo: replyPreview.centerXAnchor, constant: replyPreviewCloseButtonConstant).isActive = true
        replyPreviewCloseButton.topAnchor.constraint(equalTo: replyPreview.topAnchor, constant: 10).isActive = true
        // リプライププレビュー ニックネーム
        replyPreview.addSubview(replyPreviewNickNameLabel)
        replyPreviewNickNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        replyPreviewNickNameLabel.textColor = .fontColor
        replyPreviewNickNameLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPreviewNickNameLabel.leftAnchor.constraint(equalTo: replyPreviewIconImageView.rightAnchor, constant: 10).isActive = true
        replyPreviewNickNameLabel.topAnchor.constraint(equalTo: replyPreviewIconImageView.topAnchor, constant: 5).isActive = true
        // リプライププレビュー メッセージ画像
        let replyPreviewMessageImageViewConstant = (screenWidth / 2 - 20.0 - closeButtonWidth - closeButtonWidth / 2)
        replyPreviewMessageImageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        replyPreviewMessageImageView.clipsToBounds = true
        replyPreviewMessageImageView.contentMode = .scaleAspectFill
        replyPreviewMessageImageView.allMaskedCorners()
        replyPreview.addSubview(replyPreviewMessageImageView)
        replyPreviewMessageImageView.translatesAutoresizingMaskIntoConstraints = false
        replyPreviewMessageImageView.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        replyPreviewMessageImageView.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        replyPreviewMessageImageView.centerXAnchor.constraint(equalTo: replyPreview.centerXAnchor, constant: replyPreviewMessageImageViewConstant).isActive = true
        replyPreviewMessageImageView.topAnchor.constraint(equalTo: replyPreviewIconImageView.topAnchor).isActive = true
        // リプライププレビュー メッセージテキスト
        replyPreview.addSubview(replyPreviewMessageTextLabel)
        replyPreviewMessageTextLabel.font = UIFont.systemFont(ofSize: 14)
        replyPreviewMessageTextLabel.textColor = .lightGray
        replyPreviewMessageTextLabel.lineBreakMode = .byTruncatingTail
        replyPreviewMessageTextLabel.numberOfLines = 1
        replyPreviewMessageTextLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPreviewMessageTextLabel.leftAnchor.constraint(equalTo: replyPreviewIconImageView.rightAnchor, constant: 10).isActive = true
        replyPreviewMessageTextLabel.rightAnchor.constraint(equalTo: replyPreviewMessageImageView.leftAnchor, constant: 10).isActive = true
        replyPreviewMessageTextLabel.topAnchor.constraint(equalTo: replyPreviewNickNameLabel.bottomAnchor).isActive = true
    }
    /// replyPreviewの表示・非表示を行う
    func setReplyPreview(active: Bool) {
        if active {
            replyPreview.isHidden = false
        } else {
            replyPreview.isHidden = true
        }
    }
    
    @objc private func closeReplyPreview() {
        replyDelegate?.closeReplyPreview()
    }
    
    func showReplyPreview(room: Room, roomMessage: Message) {
        
        guard let loginUser = GlobalVar.shared.loginUser else { return }
        guard let partnerUser = room.partnerUser else { return }
        
        let messageID = roomMessage.document_id ?? ""
        let messageText = roomMessage.text
        let messagePhotos = roomMessage.photos
        let sendMessageUID = roomMessage.creator
        let customMessageType = roomMessage.type
        
        let isLoginUser  = (sendMessageUID == loginUser.uid)
        let isPartnerUID = (sendMessageUID == partnerUser.uid)
        
        var messageCustomType = "text"
        
        switch customMessageType {
        case .image:
            messageCustomType = "image"
            break
        case .sticker:
            messageCustomType = "sticker"
            break
        default:
            break
        }
        
        if isLoginUser {
            setReplyPreviewData(user: loginUser, messageID: messageID, messageCustomType: messageCustomType, messageText: messageText, messagePhotos: messagePhotos)
        } else if isPartnerUID {
            setReplyPreviewData(user: partnerUser, messageID: messageID, messageCustomType: messageCustomType, messageText: messageText, messagePhotos: messagePhotos)
        }
    }
    
    private func setReplyPreviewData(user: User, messageID: String, messageCustomType: String = "text", messageText: String, messagePhotos: [String] = []) {
        
        let profileIconImg = user.profile_icon_img
        let nickName = user.nick_name
        
        replyPreviewIconImageView.setImage(withURLString: profileIconImg)
        
        replyPreviewNickNameLabel.text = nickName
        
        replyPreviewMessageTextLabel.isHidden = false
        
        let imageText = "画像"
        let movieText = "動画"
        let stickerText = "スタンプ"
        
        switch messageCustomType {
        case "image": replyPreviewMessageTextLabel.text = imageText; break
        case "movie": replyPreviewMessageTextLabel.text = movieText; break
        case "sticker": replyPreviewMessageTextLabel.text = stickerText; break
        default: replyPreviewMessageTextLabel.text = messageText; break
        }
        
        if let messagePhoto = messagePhotos.first {
            replyPreviewMessageImageView.isHidden = false
            replyPreviewMessageImageView.setImage(withURLString: messagePhoto, isFade: true)
        } else {
            replyPreviewMessageImageView.isHidden = true
        }
        
        setReplyPreview(active: true)
    }
    
    // MARK: MessageNoticeView

    private func configureMessageNoticeView() {
        previewStackView.addArrangedSubview(noticePreview)
        noticePreview.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(noticePreviewTapped)))
        noticePreview.translatesAutoresizingMaskIntoConstraints = true
        noticePreview.heightAnchor.constraint(equalToConstant: NOTICE_VIEW_HEIGHT).isActive = true
        noticePreview.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        noticePreview.translatesAutoresizingMaskIntoConstraints = false
        noticePreview.backgroundColor = .systemGray2.withAlphaComponent(0.7)

        let screenWidth = UIScreen.main.bounds.size.width
        let labelWidth = screenWidth - 20.0 * 2
        noticePreview.addSubview(noticePreviewMessageTextLabel)
        noticePreviewMessageTextLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .semibold)
        noticePreviewMessageTextLabel.textAlignment = .left
        noticePreviewMessageTextLabel.adjustsFontSizeToFitWidth = false
        noticePreviewMessageTextLabel.textColor = .white
        noticePreviewMessageTextLabel.backgroundColor = .clear
        noticePreviewMessageTextLabel.translatesAutoresizingMaskIntoConstraints = false
        noticePreviewMessageTextLabel.centerXAnchor.constraint(equalTo: noticePreview.centerXAnchor).isActive = true
        noticePreviewMessageTextLabel.centerYAnchor.constraint(equalTo: noticePreview.centerYAnchor).isActive = true
        noticePreviewMessageTextLabel.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
    }

    @objc private func noticePreviewTapped() {
        noticeDelegate?.tappedNoticePreview()
        noticePreview.isHidden = true
    }

    func setNotificationView(_ message: Message) {
        if let nickName = room?.partnerNickname {
            noticePreviewMessageTextLabel.text = "\(nickName)：\(message.text)"
        } else if let partner = room?.partnerUser {
            noticePreviewMessageTextLabel.text = "\(partner.nick_name)：\(message.text)"
        } else {
            noticePreviewMessageTextLabel.text = message.text
        }
    }
}

