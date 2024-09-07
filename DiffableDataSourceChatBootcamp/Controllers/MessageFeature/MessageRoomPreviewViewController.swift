//
//  MessageRoomPreviewViewController.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/03.
//


import UIKit
import FirebaseFirestore

final class MessageRoomPreviewViewController: UIBaseViewController {
    
    private let room: Room
    private var roomMessages = [Message]()
    private var messageCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var backgroundImageView = UIImageView(image: UIImage(named: "message_background_image"))
    private var unreadIndex: Int?
    
    internal init(room: Room) {
        self.room = room
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        GlobalVar.shared.specificRoomMessages = ["":[]]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundImageView()
        configureMessageCollectionView()
        seUpCollectionViewCell()
        fetchMessageRoomInfoFromFirestore()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    private func scrollToBottom() {
        let lastIndexPath = IndexPath(item: roomMessages.count - 1, section: 0)
        self.messageCollectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIView.performWithoutAnimation {
                self.messageCollectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
            }
        }
    }
    
    private func setupBackgroundImageView() {
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        if GlobalVar.shared.loginUser?.is_friend_emoji == false {
            self.room.roomStatus = .normal
        }
        
        switch room.roomStatus {
        case .normal:
            // 背景
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.white
            
            break
        case .sBest:
            // 背景
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.white
            
            break
        case .ssBest:
            // 背景
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.MessageColor.lightPink
            
            break
        case .sssBest:
            // 背景
            backgroundImageView.image = UIImage(named: "message_background_image")
            
            break
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        GlobalVar.shared.thisClassName = "MessageListViewController"  // 現在はMessageListViewControllerからの導線しかないのでここで上書き
        super.dismiss(animated: flag, completion: completion)
    }
}

// CollectionView関連
extension MessageRoomPreviewViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private func seUpCollectionViewCell() {
        // Content Cell
        registerCustomCell(nibName: OwnMessageCollectionViewCell.nibName, cellIdentifier: OwnMessageCollectionViewCell.cellIdentifier)
        registerCustomCell(nibName: OwnMessageCollectionViewImageCell.nibName, cellIdentifier: OwnMessageCollectionViewImageCell.cellIdentifier)
        registerCustomCell(nibName: OwnMessageCollectionViewReplyCell.nibName, cellIdentifier: OwnMessageCollectionViewReplyCell.cellIdentifier)
        registerCustomCell(nibName: OwnMessageCollectionViewStickerCell.nibName, cellIdentifier: OwnMessageCollectionViewStickerCell.cellIdentifier)
        registerCustomCell(nibName: OtherMessageCollectionViewCell.nibName, cellIdentifier: OtherMessageCollectionViewCell.cellIdentifier)
        registerCustomCell(nibName: OtherMessageCollectionViewImageCell.nibName, cellIdentifier: OtherMessageCollectionViewImageCell.cellIdentifier)
        registerCustomCell(nibName: OtherMessageCollectionViewReplyCell.nibName, cellIdentifier: OtherMessageCollectionViewReplyCell.cellIdentifier)
        registerCustomCell(nibName: OtherMessageCollectionViewStickerCell.nibName, cellIdentifier: OtherMessageCollectionViewStickerCell.cellIdentifier)
        registerCustomCell(nibName: UnsendMessageCollectionViewCell.nibName, cellIdentifier: UnsendMessageCollectionViewCell.cellIdentifier)
        registerCustomCell(nibName: UnreadMessageCollectionViewCell.nibName, cellIdentifier: UnreadMessageCollectionViewCell.cellIdentifier)
        registerCustomCell(nibName: OwnMessageCollectionViewReplyStickerCell.identifier, cellIdentifier: OwnMessageCollectionViewReplyStickerCell.identifier)
        registerCustomCell(nibName: OtherMessageCollectionViewReplyStickerCell.identifier, cellIdentifier: OtherMessageCollectionViewReplyStickerCell.identifier)
        // Header Cell
        registCustomHeaderCell(nibName: MessageHeaderCollectionReusableView.nibName, cellIdentifier: MessageHeaderCollectionReusableView.cellIdentifier)
    }
    
    private func registerCustomCell(nibName: String, cellIdentifier: String) {
        messageCollectionView.register(
            UINib(nibName: nibName, bundle: nil),
            forCellWithReuseIdentifier: cellIdentifier
        )
    }
    
    private func registCustomHeaderCell(nibName: String, cellIdentifier: String) {
        messageCollectionView.register(
            UINib(nibName: nibName, bundle: nil),
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: cellIdentifier
        )
    }
    
    private func configureMessageCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = .supplementary
        configuration.separatorConfiguration.color = .clear
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        messageCollectionView.collectionViewLayout = layout
        messageCollectionView.delegate = self
        messageCollectionView.dataSource = self
        messageCollectionView.alwaysBounceVertical = true
        messageCollectionView.backgroundColor = .clear
        
        view.addSubview(messageCollectionView)
        
        messageCollectionView.translatesAutoresizingMaskIntoConstraints = false
        messageCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        messageCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        messageCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        messageCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
        
        view.bringSubviewToFront(messageCollectionView)
    }
    
    private func setMessageUnread() {
        guard unreadIndex == nil,
              let loginUserUID = GlobalVar.shared.loginUser?.uid,
              let unreadMessageId = room.unread_ids[loginUserUID] else { return }
        
        if let firstUnreadMessage = roomMessages.first(where: { $0.document_id == unreadMessageId }) {
            let unreadMessage = Message.generateUnreadMessage(timestamp: firstUnreadMessage.created_at)
            unreadIndex = roomMessages.firstIndex {
                $0.document_id == firstUnreadMessage.document_id
            }
            if let unreadIndex {
                roomMessages.insert(unreadMessage, at: unreadIndex)
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return roomMessages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = UICollectionViewCell()
        guard let loginUser = GlobalVar.shared.loginUser else {
            return cell
        }
        guard let partnerUser = room.partnerUser else {
            return cell
        }
        guard let message = roomMessages[safe:indexPath.row] else {
            return cell
        }
        
        if message.is_unread {
            let id = UnreadMessageCollectionViewCell.cellIdentifier
            let unreadCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! UnreadMessageCollectionViewCell
            
            return unreadCell
        }
        
        if message.is_deleted {
            let id = UnsendMessageCollectionViewCell.cellIdentifier
            let unsendCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! UnsendMessageCollectionViewCell
            unsendCell.configure(room: room, message: message)
            
            return unsendCell
        }
        if loginUser.uid == message.creator {
            if message.type == .reply {
                if message.photos.isEmpty {
                    let id = OwnMessageCollectionViewReplyCell.identifier
                    let messageReplyCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OwnMessageCollectionViewReplyCell
                    messageReplyCell.configure(message, roomStatus: room.roomStatus, delegate: self, indexPath: indexPath)
                    
                    return messageReplyCell
                } else {
                    let id = OwnMessageCollectionViewReplyStickerCell.identifier
                    let replyStickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OwnMessageCollectionViewReplyStickerCell
                    replyStickerCell.configure(loginUser, message: message, room: room, delegate: self, indexPath: indexPath)
                    
                    return replyStickerCell
                }
            } else if message.type == .sticker {
                let id = OwnMessageCollectionViewStickerCell.identifier
                let stickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OwnMessageCollectionViewStickerCell
                stickerCell.configure(loginUser, message: message, delegate: self, indexPath: indexPath)
                
                return stickerCell
            }
            if message.photos.count != 0  {
                let id = OwnMessageCollectionViewImageCell.identifier
                let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OwnMessageCollectionViewImageCell
                imageCell.configure(message, delegate: self, indexPath: indexPath)
                
                return imageCell
            } else {
                let id = OwnMessageCollectionViewCell.identifier
                let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OwnMessageCollectionViewCell
                messageCell.configure(loginUser, message: message, roomStatus: room.roomStatus, delegate: self, indexPath: indexPath)
                
                return messageCell
            }
        } else {
            if message.type == .reply {
                if message.photos.isEmpty {
                    let id = OtherMessageCollectionViewReplyCell.identifier
                    let messageReplyCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OtherMessageCollectionViewReplyCell
                    messageReplyCell.messageStackViewTrailingConstraint.constant = 100
                    messageReplyCell.configure(message, partnerUser: partnerUser, roomStatus: room.roomStatus, delegate: self, indexPath: indexPath)
                    
                    return messageReplyCell
                } else {
                    let id = OtherMessageCollectionViewReplyStickerCell.identifier
                    let replyStickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OtherMessageCollectionViewReplyStickerCell
                    replyStickerCell.configure(partnerUser, message: message, room: room, delegate: self, indexPath: indexPath)
                    
                    return replyStickerCell
                }
            } else if message.type == .sticker {
                let id = OtherMessageCollectionViewStickerCell.cellIdentifier
                let stickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OtherMessageCollectionViewStickerCell
                stickerCell.configure(partnerUser, message: message, delegate: self, indexPath: indexPath)
                
                return stickerCell
            }
            if message.photos.count != 0  {
                let id = OtherMessageCollectionViewImageCell.cellIdentifier
                let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OtherMessageCollectionViewImageCell
                imageCell.configure(partnerUser, message: message, delegate: self, indexPath: indexPath)
                
                return imageCell
            } else {
                let id = OtherMessageCollectionViewCell.cellIdentifier
                let messageCell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! OtherMessageCollectionViewCell
                messageCell.configure(partnerUser, message: message, roomStatus: room.roomStatus, delegate: self, indexPath: indexPath)
                
                return messageCell
            }
        }
    }
    
    private func scrollMessageCollectionView() {
        if let unreadIndex {
            let unreadIndexPath = IndexPath(row: unreadIndex, section: 0)
            messageCollectionView.scrollToItem(at: unreadIndexPath, at: .centeredVertically, animated: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIView.performWithoutAnimation {
                    self.messageCollectionView.scrollToItem(at: unreadIndexPath, at: .centeredVertically, animated: false)
                }
            }
        } else {
            scrollToBottom()
        }
    }
}

// メッセージ関連 --- 取得 ---
extension MessageRoomPreviewViewController {
    // メッセージ情報を取得
    private func fetchMessageRoomInfoFromFirestore() {
        
        guard let roomID = room.document_id else { return }
        var messages: [Message] = []
        
        db.collection("rooms").document(roomID).collection("messages").order(by: "created_at", descending: true).limit(to: 50).getDocuments { [weak self] (querySnapshot, error) in
            
            guard let self else { return }
            if let err = error { print("メッセージ取得失敗: \(err)"); return }
            guard let documents = querySnapshot?.documents else { return }
            
            messages = documents.map({ Message(document: $0) })
            messages.sort { (m1, m2) in
                let m1Date = m1.created_at.dateValue()
                let m2Date = m2.created_at.dateValue()
                
                return m1Date < m2Date
            }
            roomMessages = messages
            
            setMessageUnread()
            
            DispatchQueue.main.async {
                self.messageCollectionView.reloadData()
                self.scrollMessageCollectionView()
            }
        }
    }
}

extension MessageRoomPreviewViewController: OwnMessageCollectionViewReplyCellDelegate, OwnMessageCollectionViewStickerCellDelegate,
                                            OwnMessageCollectionViewImageCellDelegate, OwnMessageCollectionViewCellDelegate,
                                            OtherMessageCollectionViewReplyCellDelegate, OtherMessageCollectionViewStickerCellDelegate,
                                            OtherMessageCollectionViewImageCellDelegate, OtherMessageCollectionViewCellDelegate,
                                            OwnMessageCollectionViewReplyStickerCellDelegate, OtherMessageCollectionViewReplyStickerCellDelegate {
    
    func onOwnStickerTapped(cell: OwnMessageCollectionViewReplyStickerCell, stickerUrl: String) {
        //
    }
    
    func onOtherStickerTapped(cell: OtherMessageCollectionViewReplyStickerCell, stickerUrl: String) {
        //
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewReplyStickerCell, user: User) {
        //
    }
    
    func onOwnStickerTapped(cell: OwnMessageCollectionViewStickerCell, stickerUrl: String) {
        print(#function)
    }
    
    func longTapStickerCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        print(#function)
    }
    
    func onOwnImageViewTapped(cell: OwnMessageCollectionViewImageCell, imageView: UIImageView) {
        print(#function)
    }
    
    func longTapImageCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool, image: UIImage) {
        print(#function)
    }
    
    func longTapTextCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        print(#function)
    }
    
    func longTapReplyCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        print(#function)
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewReplyCell, user: User) {
        print(#function)
    }
    
    func onOtherStickerTapped(cell: OtherMessageCollectionViewStickerCell, stickerUrl: String) {
        print(#function)
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewStickerCell, user: User) {
        print(#function)
    }
    
    func onOtherImageViewTapped(cell: OtherMessageCollectionViewImageCell, imageView: UIImageView) {
        print(#function)
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewImageCell, user: User) {
        print(#function)
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewCell, user: User) {
        print(#function)
    }
    
    func tapReplyMessageView(messageId: String, replyMessageId: String) {
        print(#function)
    }
}
