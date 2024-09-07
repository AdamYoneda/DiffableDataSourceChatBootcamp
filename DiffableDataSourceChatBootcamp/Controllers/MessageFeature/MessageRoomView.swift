//
//  MessageRoomView.swift
//  Tauch
//
//  Created by Apple on 2023/07/22.
//

import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseFunctions

final class MessageRoomView: UIBaseViewController {
    
    @IBOutlet weak var talkView: UIStackView!
    @IBOutlet weak var talkCellsStackView: UIStackView!
    @IBOutlet weak var talkScrollView: UIScrollView!
    @IBOutlet weak var talkImageView: UIImageView!
    @IBOutlet weak var talkTitleLabel: UILabel!
    @IBOutlet weak var talkTitleHeight: NSLayoutConstraint!
    @IBOutlet weak var talkViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var talkToogleButton: UIButton!
    @IBOutlet weak var talkCellFirst: UIView!
    @IBOutlet weak var talkCellSecond: UIView!
    @IBOutlet weak var talkCellThird: UIView!
    @IBOutlet weak var talkCellFourth: UIView!
    @IBOutlet weak var talkCellFifth: UIView!
    @IBOutlet weak var talkCellSixth: UIView!
    @IBOutlet weak var talkLabelFirst: UILabel!
    @IBOutlet weak var talkLabelSecond: UILabel!
    @IBOutlet weak var talkLabelThird: UILabel!
    @IBOutlet weak var talkLabelFourth: UILabel!
    @IBOutlet weak var talkLabelFifth: UILabel!
    @IBOutlet weak var talkLabelSixth: UILabel!
    @IBOutlet weak var talkBottomView: UIStackView!
    @IBOutlet weak var talkBottomSpacerView: UIView!
    @IBOutlet weak var messageCollectionView: UICollectionView!
    @IBOutlet weak var messageCollectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingLabelConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var scrollDownButton: UIButton!
    @IBOutlet weak var autoMatchingRoomView: UIView!
    @IBOutlet weak var autoMatchingPartnerUserImageView: UIImageView!
    @IBOutlet weak var autoMatchingLabel: UILabel!
    @IBOutlet weak var autoMatchingWaveIcon: UILabel!
    @IBOutlet weak var autoMatchingWaveButton: UIButton!
    @IBOutlet weak var autoMatchingPartnerUserOnlineStatusIcon: UILabel!
    @IBOutlet weak var autoMatchingRoomViewCloseButton: UIButton!
    @IBOutlet weak var autoMatchingHeaderView: UIView!
    
    @IBOutlet weak var notMatchUserView: UIView!
    @IBOutlet weak var notMatchUserImageView: UIImageView!
    @IBOutlet weak var notMatchUserNameLabel: UILabel!
    @IBOutlet weak var notMatchUserAdressLabel: UILabel!
    @IBOutlet weak var notMatchApprovalButton: UIButton!
    @IBOutlet weak var notmatchUserProfileButton: UIButton!
    
    var room: Room?
    
    private var roomMessages = [Message]() {
        didSet {
            self.roomMessageIDs = roomMessages.sorted(by: { (m1, m2) -> Bool in
                let m1Date = m1.created_at.dateValue()
                let m2Date = m2.created_at.dateValue()
                return m1Date < m2Date
            }).map({ $0.id })
        }
    }
    private var roomMessageIDs = [Message.ID]()
    private var pastMessages = [Message]()
    private var callViewController: CallViewController?
    private var listener: ListenerRegistration?
    private var skywayToken: String?
    private var popoverItem: (indexPath:IndexPath?, image: UIImage?)
    private var reactionIndexPath: IndexPath?
    private var unreadIndex: Int?
    private var scrolledToUnreadMessage = false
    private var messageInputView = MessageInputView.init()
    private var disableLabel = UILabel()
    private var textView = UITextView()
    private var placeHolder = UILabel()
    private var cameraButton = UIButton()
    private var stampButton = UIButton()
    private var sendButton = UIButton()
    private var messageInputViewFrame: CGRect?
    private var safeAreaInsets: UIEdgeInsets?
    private var keyboardFrame: CGRect?
    private let LABEL_SIZE: CGFloat = 50
    private let BUTTON_SIZE: CGFloat = 50
    private let INPUT_VIEW_HEIGHT: CGFloat = 50
    private let INPUT_VIEW_MARGIN: CGFloat = 10
    private let TEXT_VIEW_HEIGHT: CGFloat = 36
    private let TEXT_VIEW_MARGIN: CGFloat = 8
    private let INPUT_VIEW_PADDING: CGFloat = 7.5
    private let MIN_TEXT_VIEW_HEIGHT: CGFloat = 36
    private let MAX_TEXT_VIEW_HEIGHT: CGFloat = 200
    private let TEXT_VIEW_FONT_SIZE: CGFloat = 16
    private let REPRY_VIEW_HEIGHT: CGFloat = 70
    private let NOTICE_VIEW_HEIGHT = 25.0
    private let callButton = UIButton(type: .custom)
    private let guideButton = UIButton(type: .custom)
    private let rightStackButton = UIButton(type: .custom)
    private var titleButton = UIButton(type: .custom)
    private let editNameButton = UIButton(type: .custom)
    private var lastDocument: DocumentChange? {
        didSet {
            lastDocumentSnapshot = lastDocument?.document
        }
    }
    private var lastDocumentSnapshot: QueryDocumentSnapshot?
    private var isConsecutiveCoundUpdate = false
    private var typingIndicatorView: TypingIndicatorView?
    private let sectionCount = 1
    private var isScrollToBottomAfterKeyboardShowed = false
    private var beforeTextViewHeight: CGFloat = 0.0
    private var lastTextViewSelectRange: NSRange?
    private var isFetchPastMessages = true
    private var isAlreadyReloadDataForLocalMessage = false
    private var isBackground = false
    private var messageSending = false
    private var endCallMessageModel: MessageSendModel? = nil
    private var dataSource: UICollectionViewDiffableDataSource<MessageSection, Message.ID>!
    
    // リプライ関連
    private var replyIsSelected: Bool = false
    private var replyMessageID: String?
    private var replyMessageText: String?
    private var replyMessageCreator: String?
    private var replyMessageImageUrls: [String]?
    private var replyMessageType: CustomMessageType?
    // スタンプ機能
    private var stickerIsSelected: Bool = false
    private var selectedSticker: (sticker: UIImage?, identifier: String?)
    private var keyboardIsShown: Bool = false
    
    private var adminIdCheckStatusType: AdminIdCheckStatusType = .unknown {
        didSet {
            switch adminIdCheckStatusType {
            case .approved:
                return
            case .unRequest:
                popUpIdentificationView {
                    self.tabBarController?.tabBar.isHidden = true
                }
            case .rejected:
                let alert = UIAlertController(
                    title: "本人確認失敗しました",
                    message: "提出していただいた写真又は生年月日に不備がありました\n再度本人確認書類を提出してください",
                    preferredStyle: .alert
                )
                let ok = UIAlertAction(title: "OK", style: .default) { _ in
                    self.popUpIdentificationView {
                        self.tabBarController?.tabBar.isHidden = true
                    }
                }
                alert.addAction(ok)
                present(alert, animated: true)
            case .pendAppro:
                let alert = UIAlertController(
                    title: "本人確認中です",
                    message: "現在本人確認中\n（12時間以内に承認が完了します）",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            case .unknown:
                return
            }
        }
    }
    
    private enum ReactionTypes {
        case delayedUpdate
    }
    
    private enum InterfaceActions {
        case changingKeyboardFrame
        case changingContentInsets
        case changingFrameSize
        case sendingMessage
        case scrollingToTop
        case scrollingToBottom
        case showingPreview
        case showingAccessory
        case updatingCollectionInIsolation
    }
    
    private enum ControllerActions {
        case loadingInitialMessages
        case loadingPreviousMessages
        case updatingCollection
    }
    
    private enum buttonActionType {
        case reply
        case copy
        case showImage
        case unsend
        case reaction
    }
    
    private enum CallAlertType {
        case missingData
        case notFunctionEnabled
    }
    
    private enum SendMessageAlertType {
        case nonDocumentID
        case overFileSize
        case emptyFile
        case notReadFile
    }
    
    deinit {
        updateTypingState(isTyping: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initGlobalRoomMessages()
        setMessageRoomInfo()
        setRoomStatus()
        setUpNavigation()
        setConsectiveRallyRecord()
        setUpMessageInputViewContainer()
        fetchSkyWayToken()
        configureTalkView()
        configureMessageCollectionView()
        configureDataSource()
        setCollectionViewTapGesture()
        setUpNotification()
        setUpLoadingLabel()
        observeTypingState()
        configureScrollDownButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removeMessageRoomListener()
        fetchMessagesFromFirestore()
        messageRoomStatusUpdate(statusFlg: true)
        setMessageRoomInfo()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if GlobalVar.shared.showTalkGuide {
            onTalkGuideButtonTapped()
        }
        cheackLaunchRoomCount()
        autoMessageAction()
        messageUnreadID()
        messageRead()
        receiveCallNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UserDefaults.standard.set("", forKey: "specificRoomID")
        UserDefaults.standard.synchronize()
        
        tabBarController?.tabBar.isHidden = false
        removeMessageRoomListener()
        removeMessageRoomTypingListener()
        
        if let sendOwnMessage = textView.text {
            setMessageStorage(sendOwnMessage)
            messageRoomStatusUpdate(statusFlg: false, saveTextFlg: true, saveText: sendOwnMessage)
            lastTextViewSelectRange = nil
        } else {
            messageRoomStatusUpdate(statusFlg: false)
        }
        
        messageUnreadID()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTypingState(isTyping: false)
        stashRoomMessages()
    }
    
    private func initGlobalRoomMessages() {
        GlobalVar.shared.specificRoomMessages = ["":[]] // init
    }
    
    private func stashRoomMessages() {
        if let roomId = room?.document_id {
            GlobalVar.shared.specificRoomMessages = ["":[]] // init
            GlobalVar.shared.specificRoomMessages[roomId] = self.roomMessages
        }
    }
    
    private func setRoomStatus() {
        if GlobalVar.shared.loginUser?.is_friend_emoji == false {
            self.room?.roomStatus = .normal
        }
    }
    
    private func setUpNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closedTutorial),
            name: NSNotification.Name(NotificationName.ClosedTutorial.rawValue),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(foreground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(background(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    private func setUpLoadingLabel() {
        loadingLabel.isHidden = true
        loadingLabel.clipsToBounds = true
        loadingLabel.layer.cornerRadius = 7.5
    }
    
    @objc private func foreground(_ notification: Notification) {
        print("come back foreground.")
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        isBackground = false
        messageRoomStatusUpdate(statusFlg: true)
        setMessageRoomInfo()
        messageRead(force: false)
        observeTypingState()
    
        if !roomMessages.isEmpty {
            talkView.isHidden = true
        }
    }
    
    @objc private func background(_ notification: Notification) {
        print("go to background.")
        if let sendOwnMessage = textView.text {
            setMessageStorage(sendOwnMessage)
            messageRoomStatusUpdate(statusFlg: false, saveTextFlg: true, saveText: sendOwnMessage)
            lastTextViewSelectRange = nil
        } else {
            messageRoomStatusUpdate(statusFlg: false)
        }
        isBackground = true
        updateTypingState(isTyping: false)
        removeMessageRoomTypingListener()
    }
    
    func isCollectionViewAtBottom(_ collectionView: UICollectionView) -> Bool {
        let contentHeight = collectionView.contentSize.height
        let offsetY = collectionView.contentOffset.y
        let boundsHeight = collectionView.bounds.height
        
        return contentHeight - offsetY <= boundsHeight
    }
    
    private func setMessageRoomInfo() {
        guard let room = room else {
            return
        }
        let shared = GlobalVar.shared
        let rooms = shared.loginUser?.rooms
        shared.specificRoom = room
        shared.messageCollectionView = messageCollectionView
        shared.talkView = talkView
        
        if let index = rooms?.firstIndex(where: { $0.document_id == room.document_id }) {
            if let sendMessage = rooms?[index].send_message {
                textView.text = sendMessage
            }
        }
    }
    
    private func setCollectionViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onCollectionViewTapped(_:)))
        messageCollectionView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func onCollectionViewTapped(_ sender: UITapGestureRecognizer) {
        textView.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let messageInputViewTouch = touch.location(in: messageInputView)
            let stickerPreviewTouch = touch.location(in: messageInputView.stickerPreview)
            
            if messageInputView.bounds.contains(messageInputViewTouch) {
                return
            } else if messageInputView.stickerPreview.bounds.contains(stickerPreviewTouch) {
                return
            } else {
                textView.resignFirstResponder()
            }
        }
    }
    
    private func adminIdCheckStatusTypeForMessageRoom() -> AdminIdCheckStatusType {
        guard let room = room else { return .unknown }
        guard let loginUser = GlobalVar.shared.loginUser else { return .unknown }
        let adminIdCheckStatus = loginUser.admin_checks?.admin_id_check_status
        
        if room.is_auto_matchig {
            // 本人確認未リクエスト
            if adminIdCheckStatus == nil {
                return .unRequest
            }
            // 本人確認承認済み
            else if adminIdCheckStatus == 1 {
                return .approved
            }
            // 本人確認拒否
            else if adminIdCheckStatus == 2 {
                return .rejected
            } else {
                return .pendAppro
            }
        }
        
        return .unknown
    }
}

// 自動マッチング
extension MessageRoomView {
    
    private func setUpAutoMatchingHeaderView(_ isHeaderShow: Bool) {
        if isHeaderShow {
            autoMatchingHeaderView.isHidden = false
            talkViewTopConstraint.constant = 50
            messageCollectionViewTopConstraint.constant = 50
            loadingLabelConstraint.constant = 55
        } else {
            autoMatchingHeaderView.isHidden = true
            talkViewTopConstraint.constant = 0
            messageCollectionViewTopConstraint.constant = 0
            loadingLabelConstraint.constant = 5
        }
    }
    
    private func setUpAutoMatchingView() {
        if let room = room, let partnerUser = room.partnerUser {
            let isAutoMatching = room.is_auto_matchig
            let isNormalStatus = room.roomStatus == .normal
            
            if isAutoMatching && isNormalStatus {
                setUpAutoMatchingHeaderView(true)
                
                guard let loginUser = GlobalVar.shared.loginUser else { return }
                if loginUser.admin_checks?.admin_id_check_status != 1 {
                    autoMatchingRoomViewCloseButton.isHidden = true
                }
                
                if roomMessages.count == 0 {
                    autoMatchingRoomView.isHidden = false
                    
                    let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(showProfilePage))
                    let waveIconTapGesture = UITapGestureRecognizer(target: self, action: #selector(onAutoMatchingWaveButtonTapped))
                    
                    autoMatchingPartnerUserImageView.addGestureRecognizer(profileTapGesture)
                    autoMatchingPartnerUserImageView.setImage(withURLString: partnerUser.profile_icon_img, isFade: true)
                    autoMatchingLabel.text = partnerUser.nick_name + "さんにウェーブを送信しよう。"
                    autoMatchingWaveIcon.addGestureRecognizer(waveIconTapGesture)
                    
                    let isPartnerLogin = partnerUser.is_logined
                    let partnerLogoutDate = partnerUser.logouted_at.dateValue()
                    let elaspedTime = elapsedTime(isLogin: isPartnerLogin, logoutTime: partnerLogoutDate)
                    if let elaspedTimeDay = elaspedTime[4], elaspedTimeDay > 5 {
                        autoMatchingPartnerUserOnlineStatusIcon.isHidden = true
                    } else {
                        autoMatchingPartnerUserOnlineStatusIcon.isHidden = false
                    }
                } else {
                    autoMatchingRoomView.isHidden = true
                }
            } else {
                setUpAutoMatchingHeaderView(false)
                autoMatchingRoomView.isHidden = true
            }
        }
    }
    
    @IBAction private func onAutoMatchingWaveButtonTapped(_ sender: UIButton) {
        let waveIconMessageModel = getSendMessageModel(
            text: "👋",
            inputType: .message,
            messageType: .text,
            sourceType: .none,
            imageUrls: nil,
            messageId: UUID().uuidString
        )
        sendMessageToFirestore(waveIconMessageModel)
        
        let waveTextMessageModel = getSendMessageModel(
            text: "ウェーブが送信されました！",
            inputType: .message,
            messageType: .text,
            sourceType: .none,
            imageUrls: nil,
            messageId: UUID().uuidString
        )
        sendMessageToFirestore(waveTextMessageModel)
        
        onAutoMatchingRoomViewCloseButtonTapped(sender)
    }
    
    @IBAction func onAutoMatchingRoomViewCloseButtonTapped(_ sender: UIButton) {
        autoMatchingRoomView.isHidden = true
        
        if roomMessages.count == 0 {
            talkView.isHidden = false
        }
    }
}

// 強制ルーム生成後の未マッチユーザー関連
extension MessageRoomView {
    
    private func setUpNotMatchView() {
        let isNotCreater = room?.creator != GlobalVar.shared.loginUser?.uid
        let isForceCreateRoomFromProfile = room?.room_match_status == RoomMatchStatusType.force.rawValue
        
        if isNotCreater && isForceCreateRoomFromProfile {
            if let partnerUser = room?.partnerUser {
                messageInputView.isHidden = true // 承認前は入力部分非表示
                notMatchUserView.isHidden = false
                notMatchUserImageView.setImage(withURLString: partnerUser.profile_icon_img)
                notMatchUserNameLabel.text = partnerUser.nick_name
                notMatchUserAdressLabel.text = partnerUser.address + partnerUser.address2
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onNotMatchUserImageViewTapped))
                notMatchUserImageView.addGestureRecognizer(tapGesture)
                messageCollectionViewTopConstraint.constant = notMatchUserView.frame.height
            }
        }
    }
    
    private func approval(_ room: Room, loginUser: User, partnerUser: User) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        showLoadingView(loadingView)
        
        firebaseController.approachedReply(
            loginUID: loginUser.uid,
            targetUID: partnerUser.uid,
            status: 1,
            actionType: "click"
        ) { [weak self] result in
            guard let self = self else { return }
            if result {
                if let roomId = room.document_id {
                    let updateData: [String: Any] = [
                        "creator": partnerUser.uid,
                        "room_match_status": RoomMatchStatusType.matched.rawValue,
                        "updated_at": Timestamp()
                    ]
                    db.collection("rooms").document(roomId).updateData(updateData) { error in
                        if error != nil {
                            self.alert(title: "失敗", message: "承認に失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                            return
                        }
                        
                        self.loadingView.removeFromSuperview()
                        
                        print("\(partnerUser.nick_name)さんのリクエストを承認しました！😆👍")
                        GlobalVar.shared.loginUser?.approaches.append(partnerUser.nick_name)
                        self.alert(title: "確認", message: "\(partnerUser.nick_name)さんのリクエストを承認しました！", actiontitle: "OK")
                        self.messageInputView.isHidden = false
                        self.notMatchUserView.isHidden = true
                        self.messageCollectionViewTopConstraint.constant = 0
                        
                        GlobalVar.shared.cardApproachedUsers.enumerated().forEach { index, user in
                            if user.uid == partnerUser.uid {
                                GlobalVar.shared.cardApproachedUsers.remove(at: index)
                                self.setApproachedTabBadges()
                            }
                        }
                    }
                }
            } else {
                self.loadingView.removeFromSuperview()
                self.alert(title: "失敗", message: "承認に失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
            }
        }
    }
    
    @objc private func onNotMatchUserImageViewTapped() {
        if let image = notMatchUserImageView.image {
            moveImageDetail(image: image)
        }
    }
    
    @IBAction func onNotMatchUserApprovalButtonTapped(_ sender: UIButton) {
        if let room = room, let loginUser = GlobalVar.shared.loginUser, let partnerUser = room.partnerUser {
            approval(room, loginUser: loginUser, partnerUser: partnerUser)
        }
    }
    
    @IBAction func onNotMatchUserProfileButtonTapped(_ sender: UIButton) {
        showProfilePage()
    }
}

// navigation関連
extension MessageRoomView {
    
    private func setUpNavigation() {
        
        guard let room = GlobalVar.shared.specificRoom else { return }
        guard let partnerUser = room.partnerUser else { return }
        // フッターを削除
        tabBarController?.tabBar.isHidden = true
        // ナビゲーションバーを表示する
        navigationController?.setNavigationBarHidden(false, animated: true)
        // ナビゲーションの戻るボタンを消す
        navigationItem.setHidesBackButton(true, animated: true)
        // ナビゲーションバーの設定
        hideNavigationBarBorderAndShowTabBarBorder()
        // ナビゲーションバー左ボタンを設定
        let backImage = UIImage(systemName: "chevron.backward")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action:#selector(messageListBack))
        navigationItem.leftBarButtonItem?.tintColor = .fontColor
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let partnerUID = partnerUser.uid
        let deleteUsers = GlobalVar.shared.loginUser?.deleteUsers ?? [String]()
        let isDeleteUser = (deleteUsers.firstIndex(of: partnerUID) != nil)
        
        let deactivateUsers = GlobalVar.shared.loginUser?.deactivateUsers ?? [String]()
        let isDeactivatedUser = (deactivateUsers.firstIndex(of: partnerUID) != nil)
        
        let isNotActivatedForPartner = partnerUser.is_activated == false
        let isDeletedForPartner = partnerUser.is_deleted == true
        
        let isNotUseful = isDeleteUser || isDeactivatedUser || isNotActivatedForPartner || isDeletedForPartner
        
        if isNotUseful {
            return
        }
        
        // navigationItem.titleView
        let messageRoomTitleView = MessageRoomTitleView(frame: CGRect(x: 0, y: 0, width: 200, height: 35))
        messageRoomTitleView.configure(room: room, partnerUser: partnerUser, limitIconEnabled: limitIconEnabled(room))
        messageRoomTitleView.editNameButton.addTarget(self, action: #selector(editPartnerName), for: .touchUpInside)
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(showProfilePage))
        messageRoomTitleView.addGestureRecognizer(profileTapGesture)
        navigationItem.titleView = messageRoomTitleView
        
        rightStackButton.addTarget(self, action: #selector(onEllipsisButtonTapped), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(onTalkGuideButtonTapped), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(onCallButtonTapped), for: .touchUpInside)
        
        switch room.roomStatus {
        case .normal:
            setNavigationBarColor(.accentColor)
            navigationItem.leftBarButtonItem?.tintColor = .white
            setRightBarButtonItems(background: .white, foreground: .accentColor)
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.white
        case .sBest:
            setNavigationBarColor(.white)
            navigationItem.leftBarButtonItem?.tintColor = UIColor.MessageColor.standardPink
            setRightBarButtonItems(background: UIColor.MessageColor.standardPink, foreground: .white)
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.white
        case .ssBest:
            setNavigationBarColor(UIColor.MessageColor.standardPink)
            navigationItem.leftBarButtonItem?.tintColor = .white
            setRightBarButtonItems(background: .white, foreground: UIColor.MessageColor.standardPink)
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = UIColor.MessageColor.lightPink
        case .sssBest:
            setNavigationBarColor(UIColor.MessageColor.standardPink)
            navigationItem.leftBarButtonItem?.tintColor = UIColor.MessageColor.heavyPink
            setRightBarButtonItems(background: .white, foreground: UIColor.MessageColor.standardPink)
            backgroundImageView.image = UIImage(named: "message_background_image")
        }
    }
    
    @objc private func messageListBack() {
        NotificationCenter.default.post(
            name: Notification.Name(NotificationName.MessageListBack.rawValue),
            object: self
        )
        GlobalVar.shared.messageListTableView.reloadData()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editPartnerName() {
        
        guard let thisRoom = room else { return }
        guard let partnerUser = thisRoom.partnerUser else { return }
        
        let editNameVC = EditPartnerNameViewController.init(room: thisRoom, partnerUser: partnerUser)
        editNameVC.modalPresentationStyle = .custom
        editNameVC.transitioningDelegate = self
        editNameVC.presentationController?.delegate = self
        present(editNameVC, animated: true) {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    /// Inherit from UIViewControllerTransitioningDelegate.
    /// Asks your delegate for the custom presentation controller to use for managing the view hierarchy when presenting a view controller.
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    override func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        setUpNavigation()
    }
    
    private func setNavigationBarColor(_ color: UIColor) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = nil
        appearance.backgroundImage = nil
        appearance.backgroundEffect = nil
        appearance.backgroundColor = nil
        appearance.backgroundColor = color
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
    }
    
    private func setRightBarButtonItems(background: UIColor, foreground: UIColor) {
        let callButtonConfig = UIImage.SymbolConfiguration(weight: .ultraLight)
        callButton.configuration = nil
        callButton.frame = CGRect(x: 0, y: 0, width: 50, height: 28)
        callButton.setImage(UIImage(systemName: "phone.fill", withConfiguration: callButtonConfig)?.withRenderingMode(.alwaysTemplate), for: .normal)
        callButton.backgroundColor = background
        callButton.tintColor = foreground
        callButton.clipsToBounds = true
        callButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        callButton.layer.cornerRadius = callButton.bounds.height / 2
        callButton.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        callButton.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        
        let guideButtonConfig = UIImage.SymbolConfiguration(pointSize: 13.0).applying(
            UIImage.SymbolConfiguration(paletteColors: [isUnreadTalkGuide() ? .red : foreground])
        )
        guideButton.configuration = nil
        guideButton.frame = CGRect(x: 0, y: 0, width: 50, height: 28)
        guideButton.setImage(UIImage(systemName: "book.fill", withConfiguration: guideButtonConfig)?.withRenderingMode(.alwaysTemplate), for: .normal)
        guideButton.backgroundColor = background
        guideButton.clipsToBounds = true
        guideButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        guideButton.layer.cornerRadius = guideButton.bounds.height / 2
        guideButton.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
        guideButton.heightAnchor.constraint(equalToConstant: 28.0).isActive = true
        
        rightStackButton.tintColor = background
        
        let buttonStackView = UIStackView(arrangedSubviews: [callButton, guideButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 2.0
        buttonStackView.distribution = .fillProportionally
        buttonStackView.widthAnchor.constraint(equalToConstant: 102.0).isActive = true
        
        let stackButtonItem = UIBarButtonItem(customView: buttonStackView)
        
        navigationItem.rightBarButtonItems = [rightStackButton.changeIntoBarItem(systemImage: "ellipsis"), stackButtonItem]
    }
}

extension MessageRoomView {

    /// messageCollectionViewのbottomから閾値の位置が表示されているかを判定
    private func isWithinThresholdFromBottom(threshold: CGFloat) -> Bool {
        let offsetY = messageCollectionView.contentOffset.y
        let contentHeight = messageCollectionView.contentSize.height
        let collectionViewHeight = messageCollectionView.frame.size.height

        return offsetY >= contentHeight - collectionViewHeight - threshold
    }

    private func configureScrollDownButton() {
        scrollDownButton.isHidden = true
        scrollDownButton.setShadow()
        scrollDownButton.addTarget(self, action: #selector(scrollDown), for: .touchUpInside)
    }

    /// アニメーション付きで、messageCollectionViewの1番下までスクロールする
    @objc private func scrollDown() {
        scrollToBottom(animated: true)
    }
}

// トークアドバイス
extension MessageRoomView {
    
    private func configureTalkView() {
        talkTitleHeight.constant = 40
        talkBottomView.isHidden = true
        talkBottomSpacerView.isHidden = false
        talkImageView.image = UIImage(systemName: "message.fill")
        talkTitleLabel.text = "話しかけてみましょう！"
        
        talkScrollView.layer.zPosition = -1
        talkView.setShadow()
        
        setuptalkCell(talkCellFirst, tag: 1)
        setuptalkCell(talkCellSecond, tag: 2)
        setuptalkCell(talkCellThird, tag: 3)
        setuptalkCell(talkCellFourth, tag: 4)
        setuptalkCell(talkCellFifth, tag: 5)
        setuptalkCell(talkCellSixth, tag: 6)
    }
    
    private func setuptalkCell(_ cell: UIView, tag: Int) {
        cell.tag = tag
        cell.layer.cornerRadius = 15
        cell.setShadow(opacity: 0.1)
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTaptalkViewCell)))
    }
    
    @objc private func didTaptalkViewCell(_ sender: UITapGestureRecognizer) {
        var text = ""
        switch sender.view?.tag {
        case 1:
            text = talkLabelFirst.text ?? ""
        case 2:
            text = talkLabelSecond.text ?? ""
        case 3:
            text = talkLabelThird.text ?? ""
        case 4:
            text = talkLabelFourth.text ?? ""
        case 5:
            text = talkLabelFifth.text ?? ""
        case 6:
            text = talkLabelSixth.text ?? ""
        default:
            print("想定していないViewのタップを検知しました。(システムエラー)")
        }
        let model = getSendMessageModel(
            text: text,
            inputType: .talk,
            messageType: .talk,
            sourceType: nil,
            imageUrls: nil,
            messageId: UUID().uuidString
        )
        sendMessageToFirestore(model)
    }
}

// フレンド絵文字関連
extension MessageRoomView {
    
    // ⌛️は連続記録5回以上かつ40~48hやりとりがない場合に表示
    private func limitIconEnabled(_ room: Room) -> Bool {
        let lastUpdatedEpochTime = Int(room.updated_at.seconds)
        let currentEpochTime = Int(Date().timeIntervalSince1970)
        let diffEposhTime = currentEpochTime - lastUpdatedEpochTime
        let minPeriodEpochTime = DateConst.hourInSeconds * 40
        let maxPeriodEpochTime = DateConst.hourInSeconds * 48
        
        if diffEposhTime >= minPeriodEpochTime {
            if diffEposhTime <= maxPeriodEpochTime {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    // 連続記録に必要なepochtimeと連続カウントを取得更新している
    private func setConsectiveRallyRecord() {
        guard let room = room else { return }
        guard let roomId = room.document_id else { return }
        guard let partnerUserId = room.partnerUser?.uid else { return }
        guard let loginUserId = GlobalVar.shared.loginUser?.uid else { return }
        
        Task {
            do {
                let collection = db.collection("rooms")
                let document = try await collection.document(roomId).getDocument()
                let documentData = document.data()
                
                guard let lastCountAt = documentData?["last_consective_count_at"] as? Int else {
                    try await collection.document(roomId).updateData([
                        "last_consective_count_at": 0,
                        "consective_count": 0
                    ])
                    GlobalVar.shared.consectiveCountDictionary[roomId] = 0
                    return
                }
                guard let count = documentData?["consective_count"] as? Int else {
                    try await collection.document(roomId).updateData([
                        "last_consective_count_at": 0,
                        "consective_count": 0
                    ])
                    GlobalVar.shared.consectiveCountDictionary[roomId] = 0
                    return
                }
                
                let minPeriodEpochTime = lastCountAt + DateConst.dayInSeconds
                let periodEpochTime = DateConst.hourInSeconds * 48
                let limitEposhTime = lastCountAt + periodEpochTime
                let currentEpochTime = Int(Date().timeIntervalSince1970)
                let diffEposhTime = currentEpochTime - periodEpochTime
                
                var updateData: [String: Int] = [:]
                var _createdAtArray: [Int] = []
                var _creators: [String] = []
                
                // 連続記録が0の場合ラリーを検索して初期化
                if count == 0 {
                    roomMessages.forEach { message in
                        if diffEposhTime <= message.created_at.seconds {
                            _createdAtArray.append(Int(message.created_at.seconds))
                            _creators.append(message.creator)
                        }
                    }
                    
                    if _creators.contains(loginUserId) && _creators.contains(partnerUserId) {
                        guard let lastConsectiveCountAt = _createdAtArray.max() else {
                            return
                        }
                        let consectiveCount = 1
                        updateData["last_consective_count_at"] = lastConsectiveCountAt
                        updateData["consective_count"] = consectiveCount
                        try await db.collection("rooms").document(roomId).updateData(updateData)
                        GlobalVar.shared.consectiveCountDictionary[roomId] = consectiveCount
                        return
                    }
                }
                
                // 最後のラリーから48h超えていたら連続記録をリセット
                if currentEpochTime >= limitEposhTime {
                    let consectiveCount = 0
                    updateData["last_consective_count_at"] = 0
                    updateData["consective_count"] = consectiveCount
                    try await db.collection("rooms").document(roomId).updateData(updateData)
                    GlobalVar.shared.consectiveCountDictionary[roomId] = consectiveCount
                    return
                }
                
                // 24h〜48hの間にラリーしているかを検索
                roomMessages.forEach { message in
                    if minPeriodEpochTime <= message.created_at.seconds && limitEposhTime >= message.created_at.seconds {
                        _createdAtArray.append(Int(message.created_at.seconds))
                        _creators.append(message.creator)
                    }
                }
                
                // 24h〜48hの間にラリーされていたら連続記録を更新
                if _creators.contains(loginUserId) && _creators.contains(partnerUserId) {
                    guard let lastConsectiveCountAt = _createdAtArray.max() else {
                        return
                    }
                    let consectiveCount = count + 1
                    updateData["last_consective_count_at"] = lastConsectiveCountAt
                    updateData["consective_count"] = consectiveCount
                    try await db.collection("rooms").document(roomId).updateData(updateData)
                    GlobalVar.shared.consectiveCountDictionary[roomId] = consectiveCount
                    return
                }
            } catch {
                print("🔥アイコン表示データ取得に失敗")
            }
        }
    }
}

// 通話関連
extension MessageRoomView: CallViewControllerDelegate {
    
    private func receiveCallNotification() {
        if GlobalVar.shared.receivedCallNotificaition == true {
            onCallButtonTapped()
            GlobalVar.shared.receivedCallNotificaition = false
        }
    }
    
    @objc private func onCallButtonTapped() {
        
        updateTypingState(isTyping: false)
        
        if let callData = createCallData() {
            Task {
                do {
                    let enabled = try await callFunctionEnabled(callData.loginUser, partnerUser: callData.partnerUser, rallyNum: 5)
                    if !enabled {
                        showCallFunctionAlert(.notFunctionEnabled)
                        return
                    }
                    
                    print("callData", callData.partnerName)
                    print("callData", callData.skywayToken)
                    
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(endCall),
                        name: NSNotification.Name(NotificationName.EndCall.rawValue),
                        object: nil
                    )
                    showCallViewController(
                        callData.partnerName,
                        partnerIcon: callData.partnerIcon,
                        roomName: callData.roomName,
                        skywayToken: callData.skywayToken,
                        callData: callData
                    )
                } catch {
                    showCallFunctionAlert(.missingData)
                }
            }
        }
    }
    
    private func createCallData() -> CallData? {
        guard let loginUser = GlobalVar.shared.loginUser else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        guard let room = room else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        guard let partnerUser = room.partnerUser else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        guard let partnerIconUrl = URL(string: partnerUser.profile_icon_img) else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        guard let roomName = room.document_id else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        guard let skywayToken = skywayToken else {
            showCallFunctionAlert(.missingData)
            return nil
        }
        let imageView = UIImageView()
        imageView.setImage(withURL: partnerIconUrl)
        
        var partnerNickName = partnerUser.nick_name
        
        if let nickName = room.partnerNickname { partnerNickName = nickName }
        
        let data = CallData(
            loginUser: loginUser,
            partnerUser: partnerUser,
            partnerName: partnerNickName,
            partnerIcon: imageView,
            roomName: roomName,
            skywayToken: skywayToken
        )
        
        return data
    }
    
    private func callFunctionEnabled(_ loginUser: User, partnerUser: User, rallyNum: Int) async throws -> Bool {
        guard let roomId = room?.document_id else {
            throw NSError()
        }
        
        do {
            let collection = db.collection("rooms").document(roomId).collection("messages")
            let documents = try await collection.getDocuments(source: .default).documents
            var messages = [Message]()
            
            documents.forEach { document in
                let message = Message(document: document)
                messages.append(message)
            }
            
            let ownMessages = messages.filter({
                $0.creator == loginUser.uid
            })
            let otherMessages = messages.filter({
                $0.creator != loginUser.uid
            })
            let result = ownMessages.count >= rallyNum && otherMessages.count >= rallyNum
            
            return result
        } catch {
            throw error
        }
    }
    
    private func fetchSkyWayToken() {
        callButton.isEnabled = false
        let functions = Functions.functions()
        let currentEpochTime = Int(Date().timeIntervalSince1970)
        let dayInSeconds = 86400
        var updateData: [String: Any] = [:]
        guard let room = room else {
            return
        }
        
        // print("last_updated_at_for_skyway_token:", room.lastUpdatedAtForSkyWayToken)
        // print("next_update_at_for_skyway_token:", room.lastUpdatedAtForSkyWayToken + dayInSeconds)
        
        if (room.lastUpdatedAtForSkyWayToken + dayInSeconds) <= currentEpochTime {
            functions.httpsCallable("generateSkyWayAuthToken").call { result, error in
                if let error = error {
                    print("Fail fetchSkyWayToken.")
                    print(error)
                    print(error.localizedDescription)
                } else {
                    guard let token = result?.data as? String else {
                        return
                    }
                    guard let roomID = self.room?.document_id else {
                        return
                    }
                    let lastUpdatedAtForSkyWayToken = currentEpochTime
                    
                    updateData["skyway_token"] = token
                    updateData["last_updated_at_for_skyway_token"] = lastUpdatedAtForSkyWayToken
                    
                    self.skywayToken = token
                    self.room?.skywayToken = token
                    self.room?.lastUpdatedAtForSkyWayToken = lastUpdatedAtForSkyWayToken
                    self.db.collection("rooms").document(roomID).updateData(updateData)
                    self.callButton.isEnabled = true
                }
            }
        } else {
            skywayToken = room.skywayToken
            callButton.isEnabled = true
        }
    }
    
    private func showCallViewController(_ partnerName: String, partnerIcon: UIImageView, roomName: String, skywayToken: String, callData: CallData) {
        callViewController = CallViewController(callData: callData)
        guard let callViewController = callViewController,
              let partnerUserID = self.room?.partnerUser?.uid,
              let partnerUserIconUrl = self.room?.partnerUser?.profile_icon_img,
              let roomID = self.room?.document_id else {
            return
        }
        callViewController.delegate = self
        callViewController.partnerUserIconUrl = partnerUserIconUrl
        callViewController.partnerName = partnerName
        callViewController.skywayToken = skywayToken
        callViewController.roomName = roomName
        callViewController.partnerUserID = partnerUserID
        callViewController.roomID = roomID
        callViewController.modalPresentationStyle = .fullScreen
        
        present(callViewController, animated: true)
    }
    
    private func showCallFunctionAlert(_ type: CallAlertType) {
        switch type {
        case .missingData:
            let alert = UIAlertController(title: "確認", message: "通話情報の取得に失敗しました。\n時間をおいて再度やり直してください。", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            present(alert, animated: true)
        case .notFunctionEnabled:
            let alert = UIAlertController(title: "確認", message: "通話機能はトークを5往復以上おこなってから利用することができます。", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            present(alert, animated: true)
        }
    }
    
    @objc private func endCall() {
        callViewController?.dismiss(animated: true) {
            self.callViewController = nil
            self.messageInputView.isHidden = false
            self.messageCollectionView.reloadData()
        }
    }
    
    @objc private func closedTutorial() {
        textView.resignFirstResponder()
    }
    
    func setEndCallMessage() {
        DispatchQueue.main.async {
            self.messageInputView.isHidden = false
            self.endCallMessageModel = self.getSendMessageModel(
                text: "通話しました📞",
                inputType: .message,
                messageType: .text,
                sourceType: nil,
                imageUrls: nil,
                messageId: UUID().uuidString
            )
        }
    }
    
    func setEndVideoCallMessage() {
        DispatchQueue.main.async {
            self.messageInputView.isHidden = false
            self.endCallMessageModel = self.getSendMessageModel(
                text: "ビデオ通話しました🎥",
                inputType: .message,
                messageType: .text,
                sourceType: nil,
                imageUrls: nil,
                messageId: UUID().uuidString
            )
        }
    }
    
    private func sendEndCallMessage() {
        guard let endCallMessageModel else { return }
        sendMessageToFirestore(endCallMessageModel)
        self.endCallMessageModel = nil
    }
}

// 自動メッセージ関連
extension MessageRoomView {
    // 自動メッセージ送信
    @objc private func autoMessageAction() {
        
        let autoMessage = (GlobalVar.shared.loginUser?.is_auto_message == true)
        let displayAutoMessage = (GlobalVar.shared.displayAutoMessage == true)
        let displayAutoMessageNum = UserDefaults.standard.integer(forKey: "display_auto_message_num")
        let displayAutoMessageRange = (displayAutoMessageNum < 2)
        let showAutoMessage = (autoMessage && displayAutoMessage && displayAutoMessageRange)
        if showAutoMessage {
            GlobalVar.shared.displayAutoMessage = false
            
            let displayAutoMessageNum = UserDefaults.standard.integer(forKey: "display_auto_message_num")
            
            UserDefaults.standard.set(displayAutoMessageNum + 1, forKey: "display_auto_message_num")
            UserDefaults.standard.synchronize()
            
            autoMessageMove()
        }
    }
}

// お話ガイド関連
extension MessageRoomView {
    
    @objc private func onTalkGuideButtonTapped() {
        updateTypingState(isTyping: false)
        
        let storyboard = UIStoryboard.init(name: "TalkGuideView", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "TalkGuideView") as? TalkGuideViewController else {
            return
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        
        present(navigationController, animated: true) {
            if let room = GlobalVar.shared.specificRoom {
                switch room.roomStatus {
                case .normal:
                    self.setRightBarButtonItems(background: .white, foreground: .accentColor)
                case .sBest:
                    self.setRightBarButtonItems(background: UIColor.MessageColor.standardPink, foreground: .white)
                case .ssBest, .sssBest:
                    self.setRightBarButtonItems(background: .white, foreground: UIColor.MessageColor.standardPink)
                }
            }
        }
    }
}

// 違反勧誘関連
extension MessageRoomView {
    
    @objc private func onEllipsisButtonTapped() {
        updateTypingState(isTyping: false)
        showAlertList()
    }
    
    private func showAlertList() {
        var block = UIAlertAction(title: "ブロック", style: .default) { action in
            self.block()
        }
        var report = UIAlertAction(title: "違反報告", style: .default) { action in
            self.report()
        }
        var stop = UIAlertAction(title: "勧誘専用の報告", style: .default) { action in
            self.stop()
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel)
        
        block = customAlertAction(block, image: "nosign", color: .black)
        report = customAlertAction(report, image: "megaphone", color: .black)
        stop = customAlertAction(stop, image: "megaphone.fill", color: .red)
        
        let actions = [block, report, stop, cancel]
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actions.forEach { action in
            alert.addAction(action)
        }
        
        present(alert, animated: true)
    }
    
    private func customAlertAction(_ action: UIAlertAction, image: String, color: UIColor) -> UIAlertAction {
        action.setValue(UIImage(systemName: image), forKey: "image")
        action.setValue(color, forKey: "imageTintColor")
        action.setValue(color, forKey: "titleTextColor")
        
        return action
    }
    
    private func block() {
        guard let currentUid = GlobalVar.shared.loginUser?.uid else { return }
        guard let partnerUser = room?.partnerUser else { return }
        let partnerId = partnerUser.uid
        let partnerName = partnerUser.nick_name
        
        let alert = UIAlertController(title: partnerName + "さんをブロックしますか？", message: "", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel)
        let block = UIAlertAction(title: "ブロック", style: .destructive, handler: { _ in
            self.showLoadingView(self.loadingView)
            self.firebaseController.block(loginUID: currentUid, targetUID: partnerId) { result in
                self.loadingView.removeFromSuperview()
                if result {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.alert(title: "ブロックに失敗しました", message: "不具合を運営に報告してください。", actiontitle: "OK")
                }
            }
        })
        
        alert.addAction(cancel)
        alert.addAction(block)
        
        present(alert, animated: true)
    }
    
    private func report() {
        guard let room = room else { return }
        let storyBoard = UIStoryboard.init(name: "ViolationView", bundle: nil)
        guard let viewController = storyBoard.instantiateViewController(withIdentifier: "ViolationView") as? ViolationViewController else {
            fatalError("Failed to cast to ViolationViewController")
        }
        viewController.targetUser = room.partnerUser
        viewController.category = "room"
        viewController.violationedID = room.document_id ?? ""
        viewController.closure = { (flag: Bool) -> Void in
            if flag {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        present(viewController, animated: true) {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    private func stop() {
        guard let room = room else { return }
        let storyBoard = UIStoryboard.init(name: "StopView", bundle: nil)
        guard let viewController = storyBoard.instantiateViewController(withIdentifier: "StopView") as? StopViewController else {
            fatalError("Failed to cast to StopViewController")
        }
        viewController.targetUser = room.partnerUser
        viewController.closure = { (flag: Bool) -> Void in
            if flag {
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        present(viewController, animated: true) {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    private func cheackLaunchRoomCount() {
        guard let count = UserDefaults.standard.object(forKey: "roomLaunchedTimes") as? Int else {
            return
        }
        if count > 30 {
            presentReportAlert()
        } else {
            UserDefaults.standard.set(count + 1, forKey: "roomLaunchedTimes")
        }
    }
    
    private func presentReportAlert() {
        let alert = UIAlertController(
            title: "勧誘ユーザー通報のお願い",
            message: "Touchは友達作りを目的にしているアプリです。勧誘やその他の目的を持っているユーザーを発見した場合「通報」をお願いします。運営にて厳しい処理を行います。",
            preferredStyle: .alert
        )
        let ok = UIAlertAction(title: "OK", style: .default)
        
        let frame = CGRect(x: 10, y: 115, width: 250, height: 290)
        let imageView = UIImageView()
        imageView.frame = frame
        imageView.image = UIImage(named: "BlockImage")
        
        alert.view.addConstraint(
            NSLayoutConstraint(
                item: alert.view as Any,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: 460
            )
        )
        alert.view.addSubview(imageView)
        alert.addAction(ok)
        
        present(alert, animated: true) {
            guard let roomId = self.room?.document_id else {
                return
            }
            guard let count = UserDefaults.standard.object(forKey: "roomLaunchedTimes") as? Int else {
                return
            }
            let logEventData: [String: Any] = ["roomID": roomId, "roomLaunchedTimes": count]
            Log.event(name: "showMessageRoomReportAlert", logEventData: logEventData)
            UserDefaults.standard.set(0, forKey: "roomLaunchedTimes")
        }
    }
}


// MARK: - messageCollectionView, collectionViewCellDelegate

extension MessageRoomView: OwnMessageCollectionViewImageCellDelegate,  OtherMessageCollectionViewCellDelegate,
                           OtherMessageCollectionViewImageCellDelegate, OtherMessageCollectionViewReplyCellDelegate,
                           OwnMessageCollectionViewStickerCellDelegate, OtherMessageCollectionViewStickerCellDelegate,
                           OwnMessageCollectionViewReplyCellDelegate, OwnMessageCollectionViewCellDelegate,
                           OwnMessageCollectionViewReplyStickerCellDelegate, OtherMessageCollectionViewReplyStickerCellDelegate {
    
    private func scrollToBottom(animated: Bool = false) {
        if messageCollectionView.numberOfSections > 0 {
            let section = messageCollectionView.numberOfSections
            let lastSection = section - 1
            let lastItem = messageCollectionView.numberOfItems(inSection: lastSection)
            if lastItem >= 0 {
                let lastIndexPath = IndexPath(item: lastItem - 1, section: lastSection)
                messageCollectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    private func configureMessageCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.separatorConfiguration.color = .clear
        configuration.backgroundColor = .clear
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        guard let safeArea = windowScene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets else {
            return
        }
        
        messageCollectionView.collectionViewLayout = layout
        messageCollectionView.delegate = self
        messageCollectionView.alwaysBounceVertical = true
        messageCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - (safeArea.bottom + INPUT_VIEW_HEIGHT))
    }
    
    private func getMessageFromID(id: Message.ID) -> Message? {
        self.roomMessages.first(where: { $0.id == id })
    }
    
    private func configureDataSource() {
        
        guard let loginUser = GlobalVar.shared.loginUser, let partnerUser = room?.partnerUser else { return }
        
        /* Global変数を代入 */
        GlobalVar.shared.diffableDataSource = self.dataSource
        
        /* セルの登録 */
        let unreadCellRegistration = UICollectionView.CellRegistration<UnreadMessageCollectionViewCell, Message>(
            cellNib: UnreadMessageCollectionViewCell.nib) { cell, indexPath, message in }
        let unsendCellRegistration = UICollectionView.CellRegistration<UnsendMessageCollectionViewCell, Message>(
            cellNib: UnsendMessageCollectionViewCell.nib) { cell, indexPath, message in
                cell.configure(room: self.room, message: message)
            }
        
        let ownTextCellRegistration = UICollectionView.CellRegistration<OwnMessageCollectionViewCell, Message>(
            cellNib: OwnMessageCollectionViewCell.nib
        ) { cell, indexPath, message in
            cell.configure(loginUser, message: message, roomStatus: self.room?.roomStatus, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let otherTextCellRegistration = UICollectionView.CellRegistration<OtherMessageCollectionViewCell, Message>(
            cellNib: OtherMessageCollectionViewCell.nib
        ) { cell, indexPath, message in
            cell.configure(partnerUser, message: message, roomStatus: self.room?.roomStatus, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let ownImageCellRegistration = UICollectionView.CellRegistration<OwnMessageCollectionViewImageCell, Message>(
            cellNib: OwnMessageCollectionViewImageCell.nib
        ) { cell, indexPath, message in
            cell.configure(message, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let otherImageCellRegistration = UICollectionView.CellRegistration<OtherMessageCollectionViewImageCell, Message>(
            cellNib: OtherMessageCollectionViewImageCell.nib
        ) { cell, indexPath, message in
            cell.configure(partnerUser, message: message, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let ownStickerCellRegistration = UICollectionView.CellRegistration<OwnMessageCollectionViewStickerCell, Message>(
            cellNib: OwnMessageCollectionViewStickerCell.nib
        ) { cell, indexPath, message in
            cell.configure(loginUser, message: message, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let otherStickerCellRegistration = UICollectionView.CellRegistration<OtherMessageCollectionViewStickerCell, Message>(
            cellNib: OtherMessageCollectionViewStickerCell.nib
        ) { cell, indexPath, message in
            cell.configure(partnerUser, message: message, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let ownReplyTextCellRegistration = UICollectionView.CellRegistration<OwnMessageCollectionViewReplyCell, Message>(
            cellNib: OwnMessageCollectionViewReplyCell.nib
        ) { cell, indexPath, message in
            cell.configure(message, roomStatus: self.room?.roomStatus, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let otherReplyTextCellRegistration = UICollectionView.CellRegistration<OtherMessageCollectionViewReplyCell, Message>(
            cellNib: OtherMessageCollectionViewReplyCell.nib
        ) { cell, indexPath, message in
            cell.configure(message, partnerUser: partnerUser, roomStatus: self.room?.roomStatus, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let ownReplyStickerCellRegistration = UICollectionView.CellRegistration<OwnMessageCollectionViewReplyStickerCell, Message>(
            cellNib: OwnMessageCollectionViewReplyStickerCell.nib
        ) { cell, indexPath, message in
            cell.configure(loginUser, message: message, room: self.room, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        let otherReplyStickerCellRegistration = UICollectionView.CellRegistration<OtherMessageCollectionViewReplyStickerCell, Message>(
            cellNib: OtherMessageCollectionViewReplyStickerCell.nib
        ) { cell, indexPath, message in
            cell.configure(partnerUser, message: message, room: self.room, delegate: self, indexPath: indexPath)
            if indexPath == self.reactionIndexPath {
                cell.animateReactionLabel { _ in
                    self.animateReactionLabelCompletion(indexPath)
                }
            }
        }
        
        /* データソースへ反映 */
        dataSource = UICollectionViewDiffableDataSource(
            collectionView: messageCollectionView,
            cellProvider: { [weak self] collectionView, indexPath, messageID in
                
                guard let self else {
                    fatalError("self is nil")
                }
                guard  let message = getMessageFromID(id: messageID) else {
                    fatalError("UUIDからメッセージの取得に失敗: message.document_id: \(getMessageFromID(id: messageID)?.document_id ?? "nil")")
                }
                
                if message.is_unread {
                    return collectionView.dequeueConfiguredReusableCell(using: unreadCellRegistration, for: indexPath, item: message)
                }
                if message.is_deleted {
                    return collectionView.dequeueConfiguredReusableCell(using: unsendCellRegistration, for: indexPath, item: message)
                }
                
                let isOwnMessage = loginUser.uid == message.creator
                
                switch message.type {
                case .talk, .text:
                    if isOwnMessage {
                        return collectionView.dequeueConfiguredReusableCell(using: ownTextCellRegistration, for: indexPath, item: message)
                    } else {
                        return collectionView.dequeueConfiguredReusableCell(using: otherTextCellRegistration, for: indexPath, item: message)
                    }
                case .image:
                    if isOwnMessage {
                        return collectionView.dequeueConfiguredReusableCell(using: ownImageCellRegistration, for: indexPath, item: message)
                    } else {
                        return collectionView.dequeueConfiguredReusableCell(using: otherImageCellRegistration, for: indexPath, item: message)
                    }
                case .sticker:
                    if isOwnMessage {
                        return collectionView.dequeueConfiguredReusableCell(using: ownStickerCellRegistration, for: indexPath, item: message)
                    } else {
                        return collectionView.dequeueConfiguredReusableCell(using: otherStickerCellRegistration, for: indexPath, item: message)
                    }
                case .reply:
                    switch (message.photos.isEmpty, isOwnMessage) {
                    case (true, true):
                        return collectionView.dequeueConfiguredReusableCell(using: ownReplyTextCellRegistration, for: indexPath, item: message)
                    case (true, false):
                        return collectionView.dequeueConfiguredReusableCell(using: otherReplyTextCellRegistration, for: indexPath, item: message)
                    case (false, true):
                        return collectionView.dequeueConfiguredReusableCell(using: ownReplyStickerCellRegistration, for: indexPath, item: message)
                    case (false, false):
                        return collectionView.dequeueConfiguredReusableCell(using: otherReplyStickerCellRegistration, for: indexPath, item: message)
                    }
                }
            })
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let isLastIndexPath = (indexPath.row >= roomMessages.count - 1)
        if isLastIndexPath {
            messageInputView.noticePreview.isHidden = true
        }
    }
    
    private func animateReactionLabelCompletion(_ indexPath: IndexPath) {
        if indexPath == IndexPath(row: roomMessages.count - 1, section: 0) {
            scrollToBottom(animated: true)
        }
        reactionIndexPath = nil
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<MessageSection, Message.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(self.roomMessageIDs, toSection: .main)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func setMessageUnread() {
        guard unreadIndex == nil,
              let loginUserUID = GlobalVar.shared.loginUser?.uid,
              let unreadMessageId = room?.unread_ids[loginUserUID] else { return }
        
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
    
    private func scrollToUnreadMessage() {
        guard let unreadIndex, !scrolledToUnreadMessage else { return }
        let unreadIndexPath = IndexPath(row: unreadIndex, section: 0)
        self.messageCollectionView.scrollToItem(at: unreadIndexPath, at: .centeredVertically, animated: false)
        scrolledToUnreadMessage = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrollToBottomAfterKeyboardShowed = isWithinThresholdFromBottom(threshold: 50.0)
        scrollDownButton.isHidden = isWithinThresholdFromBottom(threshold: 100.0)
        
        // 現在表示している最過去メッセージが表示されたら自動でさらに過去メッセージを取得する
        if scrollView.contentOffset.y == 0 {
            if isFetchPastMessages {
                isFetchPastMessages = false
                messageCollectionView.isScrollEnabled = false
                fetchPastMessagesFromFirestore()
                Log.event(name: "reloadMessageList")
            }
        }
    }
    
    private func moveImageDetail(image: UIImage) {
        let storyBoard = UIStoryboard.init(name: "ImageDetailView", bundle: nil)
        let imageVC = storyBoard.instantiateViewController(withIdentifier: "ImageDetailView") as! ImageDetailViewController
        imageVC.modalPresentationStyle = .overFullScreen
        imageVC.modalTransitionStyle = .crossDissolve
        imageVC.pickedImage = image
        
        present(imageVC, animated: true) {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    @objc private func showProfilePage() {
        
        updateTypingState(isTyping: false)
        
        guard let roomId = room?.document_id else {
            return
        }
        guard let partner = room?.partnerUser else {
            return
        }
        
        if partner.is_deleted {
            return
        }
        
        let logEventData: [String: Any] = ["roomID": roomId, "target": partner.uid]
        Log.event(name: "showAvatarProfile", logEventData: logEventData)
        
        textView.resignFirstResponder()
        
        let storyboard = UIStoryboard.init(name: "ProfileContainerViewController", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ProfileContainerViewController") as! ProfileContainerViewController
        viewController.user = partner
        viewController.previousClassName = "MessageRoomView"
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .overFullScreen
        navigationController.modalTransitionStyle = .crossDissolve
        
        present(navigationController, animated: true) {
            self.tabBarController?.tabBar.isHidden = true
        }
    }
    
    // MARK: Cell TapEvent
    
    func onOwnImageViewTapped(cell: OwnMessageCollectionViewImageCell, imageView: UIImageView) {
        updateTypingState(isTyping: false)
        
        if let image = imageView.image {
            moveImageDetail(image: image)
        }
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewCell, user: User) {
        showProfilePage()
    }
    
    func onOtherImageViewTapped(cell: OtherMessageCollectionViewImageCell, imageView: UIImageView) {
        updateTypingState(isTyping: false)
        
        if let image = imageView.image {
            moveImageDetail(image: image)
        }
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewImageCell, user: User) {
        showProfilePage()
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewReplyCell, user: User) {
        showProfilePage()
    }
    
    func onOwnStickerTapped(cell: OwnMessageCollectionViewStickerCell, stickerUrl: String) {
        showStickerInputView()
    }
    
    func onOtherStickerTapped(cell: OtherMessageCollectionViewStickerCell, stickerUrl: String) {
        showStickerInputView()
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewStickerCell, user: User) {
        showProfilePage()
    }
    
    func onOwnStickerTapped(cell: OwnMessageCollectionViewReplyStickerCell, stickerUrl: String) {
        showStickerInputView()
    }
    
    func onOtherStickerTapped(cell: OtherMessageCollectionViewReplyStickerCell, stickerUrl: String) {
        showStickerInputView()
    }
    
    func onProfileIconTapped(cell: OtherMessageCollectionViewReplyStickerCell, user: User) {
        showProfilePage()
    }
    
    func tapReplyMessageView(messageId: String, replyMessageId: String) {
        isFetchPastMessages = false
        
        guard let totalMessageCount = room?.message_num, roomMessages.count <= totalMessageCount else {
            alert(title: "メッセージの読み込みエラー", message: "正常に読み込めませんでした。\n不具合の報告からシステムエラーを報告してください", actiontitle: "OK")
            print("message_num: \(String(describing: room?.message_num)), roomMessages.count: \(roomMessages.count)")
            isFetchPastMessages = true
            return
        }
        
        /* メッセージ数がtotalMessageCountに達するまでfetchPastMessagesFromFirestoreを再帰的に呼び出す */
        func fetchMessagesRecursively(after lastDocument: QueryDocumentSnapshot?) {
            fetchPastMessagesFromFirestore(after: lastDocument) { error in
                guard error == nil else {
                    self.alert(title: "メッセージの読み込みエラー", message: "正常に読み込めませんでした。\n不具合の報告からシステムエラーを報告してください", actiontitle: "OK")
                    print(error?.localizedDescription ?? "リプライタップ時過去メッセージ読み込みエラー")
                    self.isFetchPastMessages = true
                    return
                }
                if self.roomMessages.contains(where: { $0.document_id == replyMessageId }) {
                    // (A) メッセージが見つかった場合
                    if let replyMessage = self.roomMessages.first(where: { $0.document_id == replyMessageId }) {
                        // 送信取り消しされている場合はここでスキップ
                        guard !replyMessage.is_deleted, let replyIndex = self.roomMessages.firstIndex(where: { $0.document_id == replyMessageId }) else {
                            self.alert(title: "送信取り消しされています。", message: "", actiontitle: "OK")
                            self.isFetchPastMessages = true
                            if let messageIndex = self.roomMessages.firstIndex(where: { $0.document_id == messageId }) {
                                self.messageCollectionView.scrollToItem(at: IndexPath(row: messageIndex, section: 0), at: .centeredVertically, animated: false)
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            self.messageCollectionView.scrollToItem(at: IndexPath(row: replyIndex, section: 0), at: .centeredVertically, animated: false)
                            self.isFetchPastMessages = true
                        }
                    }
                } else if self.roomMessages.count < totalMessageCount {
                    // (B) メッセージ数がtotalMessageCountに達していない場合、再帰呼び出し
                    fetchMessagesRecursively(after: self.lastDocumentSnapshot)
                } else {
                    // (C) メッセージが見つからず、メッセージ数がtotalMessageCountに達した場合
                    self.alert(title: "メッセージの読み込みエラー", message: "正常に読み込めませんでした。\n不具合の報告からシステムエラーを報告してください", actiontitle: "OK")
                    print("message_num: \(String(describing: self.room?.message_num)), roomMessages.count: \(self.roomMessages.count)")
                    self.isFetchPastMessages = true
                    return
                }
            }
        }
        
        if let replyMessage = roomMessages.first(where: { $0.document_id == replyMessageId }) {
            /* (1) すでに存在しているroomMessages内に、該当のメッセージが存在する場合 */
            // 送信取り消しされている場合はここでスキップ
            guard !replyMessage.is_deleted, let replyIndex = roomMessages.firstIndex(where: { $0.document_id == replyMessageId }) else {
                alert(title: "送信取り消しされています。", message: "", actiontitle: "OK")
                self.isFetchPastMessages = true
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.messageCollectionView.scrollToItem(at: IndexPath(row: replyIndex, section: 0), at: .centeredVertically, animated: false)
                self.isFetchPastMessages = true
            }
        } else {
            /* (2) すでに存在しているroomMessages内に、該当のメッセージが存在しない場合。メッセージを再帰的に取得する */
            fetchMessagesRecursively(after: lastDocumentSnapshot)
        }
    }
    
    // MARK: Cell LongTap
    
    func longTapTextCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        presentPopover(indexPath: indexPath, sourceRect: sourceRect, type: type, isLoginUser: isOwn)
    }
    
    func longTapImageCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool, image: UIImage) {
        popoverItem.image = image
        presentPopover(indexPath: indexPath, sourceRect: sourceRect, type: type, isLoginUser: isOwn)
    }
    
    func longTapReplyCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        presentPopover(indexPath: indexPath, sourceRect: sourceRect, type: type, isLoginUser: isOwn)
    }
    
    func longTapStickerCell(indexPath: IndexPath, rect sourceRect: CGRect, type: CustomMessageType, isOwn: Bool) {
        presentPopover(indexPath: indexPath, sourceRect: sourceRect, type: type, isLoginUser: isOwn)
    }
}


// MARK: - MessageInputView

extension MessageRoomView {
    
    private func setUpMessageInputViewContainer() {
        
        setUpMessageInputView()
        
        if checkRoomActive(room: room) == false {
            setUpDisableLabel()
            return
        }
        setUpTextView()
        setUpCameraButton()
        setUpStampButton()
        setUpPlaceHolder()
        setUpSendButton()
        setUpTypingIndicator()
        setUpPreview()
        setButtonTintColor()
    }
    
    private func setUpMessageInputView() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        guard let safeArea = windowScene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets else {
            return
        }
        safeAreaInsets = safeArea
        
        if let room = room, let navigationBar = navigationController?.navigationBar {
            let frame = CGRect(
                x: 0,
                y: view.frame.height - safeArea.bottom - INPUT_VIEW_HEIGHT,
                width: view.frame.width,
                height: INPUT_VIEW_HEIGHT
            )
            let screenHeight = UIScreen.main.bounds.size.height
            let replyPreviewFrame = CGRect(
                x: 0,
                y: 0,
                width: view.frame.width,
                height: REPRY_VIEW_HEIGHT
            )
            let stickerPreviewFrame = CGRect(
                x: 0,
                y: 0,
                width: view.frame.width,
                height: screenHeight * 0.2
            )
            let noticePreviewFrame = CGRect(
                x: 0,
                y: 0,
                width: view.frame.width,
                height: NOTICE_VIEW_HEIGHT
            )
            messageInputView = MessageInputView.init(frame: frame, replyPreviewFrame: replyPreviewFrame, stickerPreviewFrame: stickerPreviewFrame, noticePreviewFrame: noticePreviewFrame, room: room)
            view.addSubview(messageInputView)
            messageInputViewFrame = messageInputView.frame
            GlobalVar.shared.messageInputView = messageInputView
        }
    }
    
    private func setUpDisableLabel() {
        messageInputView.removeAllSubviews()
        let frame = CGRect(
            x: 0,
            y: 0,
            width: messageInputView.frame.width,
            height: messageInputView.frame.height
        )
        disableLabel.text = "退会済み"
        disableLabel.frame = frame
        disableLabel.tintColor = .fontColor
        disableLabel.textAlignment = .center
        disableLabel.backgroundColor = .clear
        disableLabel.font = UIFont.systemFont(ofSize: 16)
        messageInputView.addSubview(disableLabel)
    }
    
    private func setUpTextView() {
        let frame = CGRect(
            x: ((BUTTON_SIZE / 1.5) * 2) + (INPUT_VIEW_PADDING * 3),
            y: TEXT_VIEW_MARGIN,
            width: view.frame.width - ((BUTTON_SIZE / 1.5) * 3) - (INPUT_VIEW_PADDING * 5),
            height: TEXT_VIEW_HEIGHT
        )
        textView.frame = frame
        textView.font = UIFont.systemFont(ofSize: TEXT_VIEW_FONT_SIZE)
        textView.layer.cornerRadius = 10
        textView.delegate = self
        switch room?.roomStatus {
        case .normal, .sBest:
            textView.backgroundColor = .textViewColor
        case .ssBest, .sssBest:
            textView.backgroundColor = .white
            textView.layer.borderColor = UIColor.MessageColor.standardPink.cgColor
            textView.layer.borderWidth = 1.5
        case .none:
            fatalError("room is nil")
        }
        messageInputView.addSubview(textView)
        
        let user = GlobalVar.shared.loginUser
        let rooms = user?.rooms
        if let index = rooms?.firstIndex(where: { $0.document_id == room?.document_id }) {
            textView.text = GlobalVar.shared.loginUser?.rooms[index].send_message
        }
    }
    
    private func setUpPlaceHolder() {
        let frame = CGRect(
            x: 5,
            y: 0,
            width: 20,
            height: TEXT_VIEW_HEIGHT
        )
        placeHolder.frame = frame
        placeHolder.text = "Aa"
        placeHolder.textColor = .gray
        placeHolder.font = UIFont.systemFont(ofSize: TEXT_VIEW_FONT_SIZE)
        textView.addSubview(placeHolder)
    }
    
    private func setUpCameraButton() {
        let frame = CGRect(
            x: INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
        cameraButton.frame = frame
        cameraButton.backgroundColor = .clear
        cameraButton.contentMode = .scaleAspectFit
        cameraButton.contentHorizontalAlignment = .fill
        cameraButton.contentVerticalAlignment = .fill
        cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        cameraButton.addTarget(self, action: #selector(onCameraButtonTapped(_:)), for: .touchUpInside)
        messageInputView.addSubview(cameraButton)
    }
    
    private func setUpStampButton() {
        let frame = CGRect(
            x: cameraButton.frame.maxX + INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
        stampButton.frame = frame
        stampButton.setImage(UIImage(systemName: "face.smiling")?.withRenderingMode(.alwaysTemplate), for: .normal)
        stampButton.setImage(UIImage(systemName: "keyboard")?.withRenderingMode(.alwaysTemplate), for: .selected)
        stampButton.backgroundColor = .clear
        stampButton.imageView?.contentMode = .scaleAspectFit
        stampButton.contentHorizontalAlignment = .fill
        stampButton.contentVerticalAlignment = .fill
        stampButton.addTarget(self, action: #selector(onStampButtonTapped(_:)), for: .touchUpInside)
        messageInputView.addSubview(stampButton)
        stampButton.isSelected = false
    }
    
    private func setUpSendButton() {
        let frame = CGRect(
            x: messageInputView.frame.width - (BUTTON_SIZE / 1.5) - INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
        sendButton.frame = frame
        sendButton.backgroundColor = .clear
        stampButton.contentMode = .scaleAspectFit
        stampButton.contentHorizontalAlignment = .fill
        stampButton.contentVerticalAlignment = .fill
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.addTarget(self, action: #selector(onSendButtonTapped(_:)), for: .touchUpInside)
        
        if textView.text == "" {
            sendButton.isEnabled = false
            placeHolder.isHidden = false
        } else {
            sendButton.isEnabled = true
            placeHolder.isHidden = true
        }
        
        messageInputView.addSubview(sendButton)
    }
    
    private func setUpTypingIndicator() {
        if let _room = self.room {
            typingIndicatorView = TypingIndicatorView(frame: CGRect(x: 0, y: -25, width: view.bounds.width, height: 25), room: _room)
            if let _typingIndicatorView = typingIndicatorView {
                messageInputView.addSubview(_typingIndicatorView)
            }
        }
        typingIndicatorView?.indicatorView.stopAnimating()
        typingIndicatorView?.isHidden = true
    }
    
    private func setUpPreview() {
        
        messageInputView.stickerDelegate = self
        messageInputView.setStickerPreview(active: false)
        
        messageInputView.replyDelegate = self
        setReplyPreview(active: false)
        
        messageInputView.noticeDelegate = self
        messageInputView.noticePreview.isHidden = true
    }
    
    private func setButtonTintColor() {
        switch room?.roomStatus {
        case .normal:
            cameraButton.tintColor = .accentColor
            stampButton.tintColor = .accentColor
            sendButton.tintColor = .accentColor
        case .sBest, .ssBest:
            cameraButton.tintColor = UIColor.MessageColor.standardPink
            stampButton.tintColor = UIColor.MessageColor.standardPink
            sendButton.tintColor = UIColor.MessageColor.standardPink
        case .sssBest:
            cameraButton.tintColor = UIColor.MessageColor.heavyPink
            stampButton.tintColor = UIColor.MessageColor.heavyPink
            sendButton.tintColor = UIColor.MessageColor.heavyPink
        case .none:
            fatalError("room is nil")
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let type = adminIdCheckStatusTypeForMessageRoom()
        if type == .unRequest || type == .rejected || type == .pendAppro {
            textView.resignFirstResponder()
            adminIdCheckStatusType = type
            return
        }
            
        guard let room = room else { return }
        if room.roomStatus == .sssBest {
            // sssBestはkeyboard表示のときは背景画像と同系色にしてく
            messageInputView.backgroundColor = UIColor.MessageColor.lightPink
        } else {
            messageInputView.roomStatus = room.roomStatus
        }
        
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let keyboardInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        keyboardFrame = keyboardInfo.cgRectValue
        drawMessageInputView()
        
        if let lastRange = lastTextViewSelectRange {
            textView.selectedRange = lastRange
        }
        
        if isScrollToBottomAfterKeyboardShowed {
            scrollToBottom()
        }
        keyboardIsShown = true
        if !textView.text.isEmpty && !isBackground {
            updateTypingState(isTyping: true)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification?) {
        guard let room = room else { return }
        if room.roomStatus == .sssBest {
            // sssBestはkeyboard非表示のときは透明にする
            messageInputView.backgroundColor = .clear
        } else {
            messageInputView.roomStatus = room.roomStatus
        }
        
        guard let messageInputViewFrame = messageInputViewFrame else {
            return
        }
        
        messageInputView.frame = CGRect(
            x: messageInputViewFrame.origin.x,
            y: messageInputViewFrame.origin.y,
            width: messageInputView.frame.width,
            height: messageInputView.frame.height
        )
        messageCollectionView.contentInset =  UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0
        )
        textView.frame = CGRect(
            x: textView.frame.origin.x,
            y: textView.frame.origin.y,
            width: textView.frame.width,
            height: TEXT_VIEW_HEIGHT
        )
        initInputViewButtonFrame()
        
        if isCollectionViewAtBottom(messageCollectionView) {
            scrollToBottom()
        }
        
        keyboardIsShown = false
        updateTypingState(isTyping: false)
    }
    
    private func drawMessageInputView() {
        var height = textView.contentSize.height
        
        if height < MIN_TEXT_VIEW_HEIGHT {
            height = MIN_TEXT_VIEW_HEIGHT
        } else if MAX_TEXT_VIEW_HEIGHT < height {
            height = MAX_TEXT_VIEW_HEIGHT
        }
        
        if let keyboardFrame = keyboardFrame {
            textView.frame = CGRect(
                x: textView.frame.origin.x,
                y: textView.frame.origin.y,
                width: textView.frame.width,
                height: height
            )
            messageInputView.frame = CGRect(
                x: messageInputView.frame.origin.x,
                y: view.frame.height - keyboardFrame.size.height - (textView.frame.height + (TEXT_VIEW_MARGIN * 2)),
                width: view.frame.width,
                height: height + (TEXT_VIEW_MARGIN * 2)
            )
            messageCollectionView.contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: (keyboardFrame.height + height) - INPUT_VIEW_HEIGHT,
                right: 0
            )
            initInputViewButtonFrame()
        }
    }
    
    private func initTextView() {
        placeHolder.isHidden = false
        sendButton.isEnabled = false
        textView.text = ""
        setMessageStorage(textView.text)
        textViewDidChange(textView)
    }
    
    private func initInputViewButtonFrame() {
        cameraButton.frame = CGRect(
            x: INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
        stampButton.frame = CGRect(
            x: cameraButton.frame.maxX + INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
        sendButton.frame = CGRect(
            x: messageInputView.frame.width - (BUTTON_SIZE / 1.5) - INPUT_VIEW_PADDING,
            y: textView.frame.maxY - (BUTTON_SIZE / 2) - INPUT_VIEW_PADDING,
            width: BUTTON_SIZE / 1.5,
            height: BUTTON_SIZE / 2
        )
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == "" {
            sendButton.isEnabled = false
            placeHolder.isHidden = false
        } else {
            sendButton.isEnabled = true
            placeHolder.isHidden = true
        }
        lastTextViewSelectRange = textView.selectedRange
        drawMessageInputView()
        updateTypingState(isTyping: !textView.text.isEmpty)
        
        if isCollectionViewAtBottom(messageCollectionView) {
            scrollToBottom()
            return
        }
        
        // textViewの行数減少に合わせてcollectionViewも追従させる
        if textView.frame.height >= MAX_TEXT_VIEW_HEIGHT {
            messageCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: messageInputView.frame.minY)
        } else if textView.frame.height < beforeTextViewHeight {
            let currentOffset = messageCollectionView.contentOffset
            let point = CGPoint(x: currentOffset.x, y: currentOffset.y - 19)
            messageCollectionView.setContentOffset(point, animated: false)
            messageCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: messageInputView.frame.minY)
        }
        
        beforeTextViewHeight = textView.frame.height
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // textViewの改行に合わせてcollectionViewも追従させる
        if text == "\n" {
            let currentOffset = messageCollectionView.contentOffset
            let point = CGPoint(x: currentOffset.x, y: currentOffset.y + 19)
            
            if textView.frame.height < MAX_TEXT_VIEW_HEIGHT {
                messageCollectionView.setContentOffset(point, animated: false)
                messageCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: messageInputView.frame.minY)
            }
        }
        
        return true
    }
    
    @objc private func onCameraButtonTapped(_ sender: UIButton) {
        textView.resignFirstResponder()
        updateTypingState(isTyping: false)
        
        let type = adminIdCheckStatusTypeForMessageRoom()
        if type == .unRequest || type == .rejected || type == .pendAppro {
            textView.resignFirstResponder()
            adminIdCheckStatusType = type
            return
        }
        
        let selectAction = UIAlertAction(title: "ライブラリから写真を選ぶ", style: .default) { action in
            self.presentPicker()
        }
        let cameraAction = UIAlertAction(title: "カメラで写真を撮る", style: .default) { action in
            self.presentCamera()
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .default)
        
        let alert = UIAlertController(title: "送信する画像を選択してください", message: nil, preferredStyle: .actionSheet)
        alert.addAction(selectAction)
        alert.addAction(cameraAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @objc private func onStampButtonTapped(_ sender: UIButton) {
        updateTypingState(isTyping: false)
        
        let type = adminIdCheckStatusTypeForMessageRoom()
        if type == .unRequest || type == .rejected || type == .pendAppro {
            textView.resignFirstResponder()
            adminIdCheckStatusType = type
            return
        }
        
        switchSelectedStateAction()
    }
    
    @objc private func onSendButtonTapped(_ sender: UIButton) {
        updateTypingState(isTyping: false)
        /* (1) 本人確認しているかをチェック */
        if adminCheckStatus() == false {
            return
        }
        self.messageSending = true
        /* (2) リプライ返信/スタンプ送信/テキストメッセージ送信かを判定 */
        if replyIsSelected {
            if stickerIsSelected {
                if textView.text.isEmpty {
                    if !textView.isFirstResponder {
                        keyboardWillHide(nil)
                    }
                    /* (3-A) リプライ（スタンプ）*/
                    sendMessageSticker()
                } else {
                    /* (3-B) リプライ返信(テキスト) */
                    let model = getSendMessageModel(
                        text: textView.text,
                        inputType: .reply,
                        messageType: .reply,
                        sourceType: nil,
                        imageUrls: nil,
                        messageId: UUID().uuidString,
                        replyMessageId: replyMessageID,
                        replyMessageText: replyMessageText,
                        replyMessageCreator: replyMessageCreator,
                        replyMessageImageUrls: replyMessageImageUrls,
                        replyMessageType: replyMessageType
                    )
                    sendMessageToFirestore(model)
                    setReplyPreview(active: false)
                    scrollToBottom()
                    initTextView()
                    
                    if !textView.isFirstResponder {
                        keyboardWillHide(nil)
                    }
                    
                    /* (4) スタンプ送信  */
                    sendMessageSticker()
                }
            } else {
                /* (3-C) リプライ返信(テキスト)  */
                let model = getSendMessageModel(
                    text: textView.text,
                    inputType: .reply,
                    messageType: .reply,
                    sourceType: nil,
                    imageUrls: nil,
                    messageId: UUID().uuidString,
                    replyMessageId: replyMessageID,
                    replyMessageText: replyMessageText,
                    replyMessageCreator: replyMessageCreator,
                    replyMessageImageUrls: replyMessageImageUrls,
                    replyMessageType: replyMessageType
                )
                sendMessageToFirestore(model)
                setReplyPreview(active: false)
                scrollToBottom()
                initTextView()
                
                if !textView.isFirstResponder {
                    keyboardWillHide(nil)
                }
            }
            
        } else if stickerIsSelected {
            /* (3-D) スタンプ送信  */
            sendMessageSticker()
            
            /* (4) テキストメッセージ送信  */
            if !textView.text.isEmpty {
                let model = getSendMessageModel(
                    text: textView.text,
                    inputType: .message,
                    messageType: .text,
                    sourceType: nil,
                    imageUrls: nil,
                    messageId: UUID().uuidString
                )
                sendMessageToFirestore(model)
                scrollToBottom()
                initTextView()
                
                if !textView.isFirstResponder {
                    keyboardWillHide(nil)
                }
            }
        } else {
            /* (3-E) テキストメッセージ送信  */
            let model = getSendMessageModel(
                text: textView.text,
                inputType: .message,
                messageType: .text,
                sourceType: nil,
                imageUrls: nil,
                messageId: UUID().uuidString
            )
            sendMessageToFirestore(model)
            initTextView()
            
            if !textView.isFirstResponder {
                keyboardWillHide(nil)
            }
        }
    }
}


//MARK: - Message Sticker

extension MessageRoomView: StickerKeyboardViewDelegate, MessageInputViewStickerDelegate {
    
    /// スタンプ用キーボードを表示させる
    private func showStickerInputView() {
        
        updateTypingState(isTyping: false)
        
        if textView.inputView == nil {
            
            let stickerKeyboardView = StickerKeyboardView()
            var frame = stickerKeyboardView.frame
            frame.size.height = UIScreen.main.bounds.height * 0.35
            stickerKeyboardView.frame = frame
            stickerKeyboardView.delegate = self
            textView.inputView = stickerKeyboardView
            textView.reloadInputViews()
            stampButton.isSelected = true
            
            if !keyboardIsShown {
                textView.becomeFirstResponder(); keyboardIsShown = true
            }
        }
    }
    
    /// stickerInputButtonの選択状態に応じて、スタンプ用キーボードの表示・非表示を行う
    private func switchSelectedStateAction() {
        if stampButton.isSelected {
            textView.inputView = nil
            messageInputView.stickerPreviewImageView.image = nil
            selectedSticker = (nil, nil)
            messageInputView.setStickerPreview(active: false)
        } else {
            let stickerKeyboardView = StickerKeyboardView()
            var frame = stickerKeyboardView.frame
            frame.size.height = UIScreen.main.bounds.height * 0.35
            stickerKeyboardView.frame = frame
            stickerKeyboardView.delegate = self
            textView.inputView = stickerKeyboardView
        }
        
        textView.reloadInputViews()
        stampButton.isSelected.toggle()
        
        if !keyboardIsShown {
            textView.becomeFirstResponder(); keyboardIsShown = true
        }
    }
    
    /// スタンプのプレビューを閉じる
    func closeStickerPreview() {
        messageInputView.setStickerPreview(active: false)
        messageInputView.stickerPreviewImageView.image = nil
        selectedSticker = (nil, nil)
        if textView.text == "" {
            sendButton.isEnabled = false
        }
        stickerIsSelected = false
        observeTypingState()
    }
    
    func didSelectMessageSticker(_ image: UIImage, identifier: String) {
        removeMessageRoomTypingListener()
        if selectedSticker.sticker == image {
            /* 同じスタンプをタップ2回目 */
            sendMessageSticker()
        } else {
            /* 1回目タップ or 違うスタンプをタップ */
            messageInputView.stickerPreviewImageView.image = image
            selectedSticker.sticker = image
            selectedSticker.identifier = identifier
            sendButton.isEnabled = true
            stickerIsSelected = true
            messageInputView.setStickerPreview(active: true)
        }
    }
    
    func didSelectMessageSticker(_ urlString: String) {
        // action
    }
    
    /// スタンプ機能でのエラーアラートを表示する
    private func showStickerErrorAlert(errorCase: Int) {
        let message = (errorCase == 0) ? "正常に処理できませんでした。\n運営にお問い合わせください。" : "スタンプのアップロードに失敗しました。\nアプリを再起動して再度実行をしてください。"
        let alert = UIAlertController(title: "スタンプ送信エラー", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { [weak self] action in
            if errorCase == 0 { return }
            guard let weakSelf = self else { return }
            weakSelf.roomMessages.removeLast()
            weakSelf.messageCollectionView.reloadData()
            weakSelf.scrollToBottom()
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    // ローカルへメッセージを反映させた後、Firebaseへのアップロードを行う
    func sendMessageSticker() {
        updateTypingState(isTyping: false)
        
        guard let selectedSticker = self.selectedSticker.sticker,
              let identifier = self.selectedSticker.identifier,
              let roomId = room?.document_id,
              let loginUser = GlobalVar.shared.loginUser,
              let partnerUser = room?.partnerUser else {
            showStickerErrorAlert(errorCase: 0)
            return
        }
        
        let localModel: MessageSendModel = if replyIsSelected {
            MessageSendModel(
                text: "スタンプが送信されました",
                inputType: .sticker,
                messageType: .reply,
                sourceType: nil,
                imageUrls: nil,
                sticker: selectedSticker,
                stickerIdentifier: identifier,
                messageId: UUID().uuidString,
                replyMessageId: replyMessageID,
                replyMessageText: replyMessageText,
                replyMessageCreator: replyMessageCreator,
                replyMessageImageUrls: replyMessageImageUrls,
                replyMessageType: replyMessageType
            )
        } else {
            MessageSendModel(
                text: "スタンプが送信されました",
                inputType: .sticker,
                messageType: .sticker,
                sourceType: nil,
                imageUrls: nil,
                sticker: selectedSticker,
                stickerIdentifier: identifier,
                messageId: UUID().uuidString,
                replyMessageId: nil,
                replyMessageText: nil,
                replyMessageCreator: nil,
                replyMessageImageUrls: nil,
                replyMessageType: nil
            )
        }
        let messageId = localModel.messageId
        let members = [loginUser.uid, partnerUser.uid]
        let sendTime = Timestamp()
        let messageType = localModel.messageType
        
        // 1. 先にローカルへメッセージを反映させる
        addLocalMessages(
            messageId: messageId,
            messageText: localModel.text,
            type: messageType,
            members: members,
            sendTime: sendTime,
            imageUrls: localModel.imageUrls,
            sticker: localModel.sticker,
            replyMessageId: localModel.replyMessageId
        )
        
        // 2. Storageへスタンプ画像をアップロードする
        uploadStickerToStrage(roomId, sticker: selectedSticker) { stickerUrl in
            let uploadModel = MessageSendModel(
                text: localModel.text,
                inputType: localModel.inputType,
                messageType: localModel.messageType,
                sourceType: localModel.sourceType,
                imageUrls: [stickerUrl],
                sticker: localModel.sticker,
                stickerIdentifier: identifier,
                messageId: localModel.messageId,
                replyMessageId: localModel.replyMessageId,
                replyMessageText: localModel.replyMessageText,
                replyMessageCreator: localModel.replyMessageCreator,
                replyMessageImageUrls: localModel.replyMessageImageUrls,
                replyMessageType: localModel.replyMessageType
            )
            // 3. URL取得後、Firestoreへメッセージをアップロードする
            self.sendMessageToFirestore(uploadModel)
        }
        
        closeStickerPreview()
        if replyIsSelected {
            setReplyPreview(active: false)
        }
    }
    
    /// スタンプをStorageへアップロードする。メタデータを作成する。
    private func uploadStickerToStrage(_ roomId: String, sticker: UIImage, completion: @escaping (String) -> Void) {
        let referenceName = "rooms/\(roomId)"
        let folderName = "messages"
        let messageId = UUID().uuidString
        
        let fileId = UUID().uuidString
        let fileName = "sticker_\(fileId).png"
        let metadata = [
            "type": "message",
            "room_id": roomId,
            "message_id": messageId,
            "file_id": fileId
        ]
        
        firebaseController.uploadStickerToFireStorage(
            sticker: sticker,
            referenceName: referenceName,
            folderName: folderName,
            fileName: fileName,
            customMetadata: metadata,
            completion: { result in
                completion(result)
            }
        )
    }
}

// メッセージ関連 --- 取得 ---
extension MessageRoomView {
    
    private func sortMessages(_ messages: [Message], sendAt: String) -> [Message] {
        let filterMessages = messages.filter({ elaspedTime.string(from: $0.created_at.dateValue()) == sendAt })
        let sortMessages = filterMessages.sorted(by: { $0.created_at.dateValue() < $1.created_at.dateValue() })
        
        return sortMessages
    }
    
    /// ルーム内メッセージを監視するリスナーをアタッチする
    private func attachMessageRoomListener(room: Room, roomId: String, from lastDocument: QueryDocumentSnapshot?) {
        if let lastDocument {
            // (A-1) 既存のリスナーをデタッチ
            removeMessageRoomListener()
            print("\(#function) - 特定のメッセージルーム監視リスナーのアタッチ ルームID : \(roomId)")
            // (A-2) 取得しているドキュメントの最後尾からリスナーをつける
            let collection = db.collection("rooms").document(roomId).collection("messages")
            let query = collection.order(by: "updated_at", descending: false).start(atDocument: lastDocument)
            listener = query.addSnapshotListener { snapshots, error in
                self.dealWithSnapshots(room: room, snapshots: snapshots, error: error)
            }
        } else {
            print("\(#function) - 特定のメッセージルーム監視リスナーのアタッチ ルームID : \(roomId)")
            // (B-1) ドキュメント全体にリスナーをつける
            let collection = db.collection("rooms").document(roomId).collection("messages")
            listener = collection.addSnapshotListener { snapshots, error in
                self.dealWithSnapshots(room: room, snapshots: snapshots, error: error)
            }
        }
    }
    
    private func dealWithSnapshots(room: Room, snapshots: QuerySnapshot?, error: Error?) {
        guard let snapshots, error == nil else {
            print("ルーム内メッセージ監視リスナーのアタッチに失敗: \(error!)")
            return
        }
        // print("\(#function) - リスナーが監視するメッセージ数: \(snapshots.count)")
        
        let documentChanges = snapshots.documentChanges
        documentChanges.forEach { documentChange in
            switch documentChange.type {
            case .added:
                self.addMessageDocument(documentChange)
                if !self.isBackground {
                    self.updateMessageReadFlug(room, messageDocument: documentChange)
                }
            case .modified:
                self.unsendRoomMessage(messageDocument: documentChange)
                self.updateMessageReaction(messageDocument: documentChange)
                self.updateMessageReadFlug(room, messageDocument: documentChange)
            case .removed:
                print("メッセージを削除する:\(documentChange.document.documentID)")
            }
        }
        if !roomMessages.isEmpty {
            self.talkView.isHidden = true
        }
    }
    
    private func removeMessageRoomListener() {
        if let listener = listener {
            listener.remove()
            self.listener = nil
            print("MessageRoomView: リスナーをデタッチ！")
        }
    }
    
    /// 初回のメッセージ取得
    private func fetchMessagesFromFirestore() {
        guard let room = room, let roomId = room.document_id else { return }
        
        let globalRoomMessages = GlobalVar.shared.specificRoomMessages[roomId]
        if let globalRoomMessages, !globalRoomMessages.isEmpty {
            print(#function, "[A] グローバル変数に保存されたメッセージを使用。globalRoomMessages.count: \(globalRoomMessages.count)")
            self.roomMessages = globalRoomMessages
            DispatchQueue.main.async {
                self.setMessageUnread()
                self.attachMessageRoomListener(room: room, roomId: roomId, from: self.lastDocumentSnapshot)
                self.applySnapshot()
                self.setUpAutoMatchingView()
                if self.roomMessages.isEmpty {
                    self.talkView.isHidden = self.isHiddenTalkView(room: room)
                } else {
                    self.talkView.isHidden = true
                }
                self.sendEndCallMessage()
                self.scrollToBottom()
                self.scrollToUnreadMessage()
            }
        } else {
            print(#function, "[B] グローバル変数に保存されたメッセージが存在しないため、Firestoreから取得する。")
            let collection = db.collection("rooms").document(roomId).collection("messages")
            let query = collection.order(by: "created_at", descending: true).limit(to: 30)
            query.getDocuments { snapshots, error in
                if let error = error {
                    print("Error fetchPastMessage:", error)
                    let alert = UIAlertController(title: "読み込み失敗", message: nil, preferredStyle: .alert)
                    self.present(alert, animated: true) {
                        self.hideLoadingLabelAnimationAndUpdateFlug()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        alert.dismiss(animated: true)
                    }
                    return
                }
                
                self.lastDocumentSnapshot = snapshots?.documents.last
                
                if let documents = snapshots?.documentChanges {
                    documents.forEach { documentChange in
                        let message = Message(document: documentChange.document)
                        if self.roomMessages.firstIndex(where: { $0.document_id == message.document_id }) != nil {
                            return
                        }
                        self.roomMessages.insert(message, at: 0)
                    }
                }
                
                DispatchQueue.main.async {
                    self.setMessageUnread()
                    self.attachMessageRoomListener(room: room, roomId: roomId, from: self.lastDocumentSnapshot)
                    self.applySnapshot()
                    self.setUpAutoMatchingView()
                    if self.roomMessages.isEmpty {
                        self.talkView.isHidden = self.isHiddenTalkView(room: room)
                    } else {
                        self.talkView.isHidden = true
                    }
                    self.sendEndCallMessage()
                    self.scrollToBottom()
                    self.scrollToUnreadMessage()
                }
            }
        }
    }
    
    private func fetchPastMessagesFromFirestore() {
        guard let room, let roomId = room.document_id, let lastDocument = self.lastDocumentSnapshot, !messageSending else {
            messageCollectionView.isScrollEnabled = true
            isFetchPastMessages = true
            return
        }
        
        loadingLabel.isHidden = false
        
        let collection = db.collection("rooms").document(roomId).collection("messages")
        let query = collection.order(by: "updated_at", descending: true).limit(to: 30)
        query.start(afterDocument: lastDocument).getDocuments { snapshots, error in
            if let error = error {
                print("Error fetchPastMessage:", error)
                let alert = UIAlertController(title: "読み込み失敗", message: nil, preferredStyle: .alert)
                self.present(alert, animated: true) {
                    self.hideLoadingLabelAnimationAndUpdateFlug()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    alert.dismiss(animated: true)
                }
                return
            }
            
            guard let documentChanges = snapshots?.documentChanges else {
                return
            }
            self.lastDocumentSnapshot = snapshots?.documents.last
            
            documentChanges.forEach { documentChange in
                let message = Message(document: documentChange.document)
                if self.roomMessages.firstIndex(where: { $0.document_id == message.document_id }) != nil {
                    return
                }
                self.roomMessages.insert(message, at: 0)
            }
            
            self.applySnapshot()
            self.messageCollectionView.scrollToItem(at: IndexPath(item: documentChanges.count, section: 0), at: .top, animated: false)
            
            self.hideLoadingLabelAnimationAndUpdateFlug()
            if let lastDocumentSnapshot = self.lastDocumentSnapshot {
                self.attachMessageRoomListener(room: room, roomId: roomId, from: lastDocumentSnapshot)
            }
        }
    }
    
    /// lastDocumentから1回最大100件のメッセージを取得する
    private func fetchPastMessagesFromFirestore(after lastDocumentSnapshot: QueryDocumentSnapshot?, completion: @escaping (Error? ) -> () = {_ in }) {
        guard let room, let roomId = room.document_id, let lastDocumentSnapshot else { print(#function); return }
        
        let collection = db.collection("rooms").document(roomId).collection("messages")
        let query = collection.order(by: "created_at", descending: true).limit(to: 100)
        query.start(afterDocument: lastDocumentSnapshot).getDocuments { snapshots, error in
            if let error {
                print(#function, error)
                completion(error)
            } else {
                guard let documents = snapshots?.documents else {
                    completion(nil)
                    return
                }
                var fetchedMessages: [Message] = []
                documents.forEach { document in
                    let newMessage = Message(document: document)
                    guard self.roomMessages.firstIndex(where: { $0.document_id == newMessage.document_id }) == nil else { return }
                    fetchedMessages.append(newMessage)
                }
                fetchedMessages.sort { (m1, m2) -> Bool in
                    let m1Date = m1.created_at.dateValue()
                    let m2Date = m2.created_at.dateValue()
                    
                    return m1Date < m2Date
                }
                self.lastDocumentSnapshot = documents.last
                self.roomMessages.insert(contentsOf: fetchedMessages, at: 0)
                self.applySnapshot()
                
                if let lastDocumentSnapshot = self.lastDocumentSnapshot {
                    self.attachMessageRoomListener(room: room, roomId: roomId, from: lastDocumentSnapshot)
                }
                completion(nil)
            }
        }
    }
    
    private func addMessageDocument(_ messageDocument: DocumentChange) {
        let document = messageDocument.document
        let message = Message(document: document)
        let messageID = message.id
        
        // すでに存在するメッセージの場合は追加しない
        guard !roomMessages.contains(where: { $0.document_id == message.document_id }) else { return }
        
        roomMessages.insert(message, at: 0)
        roomMessages.sort { (m1, m2) -> Bool in
            let m1Date = m1.created_at.dateValue()
            let m2Date = m2.created_at.dateValue()
            
            return m1Date < m2Date
        }
        
        var snapshot = dataSource.snapshot()
        snapshot.appendItems([messageID], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true) {
            self.setNotificationView(message)
        }
    }
    
    private func updateMessageReadFlug(_ room: Room, messageDocument: DocumentChange) {
        guard let userId = GlobalVar.shared.loginUser?.uid, let roomId = room.document_id else { return }
        
        let document = messageDocument.document
        let messageId = document.documentID
        let message = Message(document: document)
        let creator = message.creator
        
        // 相手のメッセージを追加時に実行
        let isUnreadMessage = ( userId != creator ) && ( message.read == false )
        if isUnreadMessage {
            let collection = db.collection("rooms").document(roomId).collection("messages")
            collection.document(messageId).updateData(["read": true])
        }
        
        // 既読フラグ更新時に実行
        let isOwnReadMessage = ( userId == creator ) && ( message.read == true )
        if isOwnReadMessage,
           let messageIndex = roomMessages.firstIndex(where: { $0.document_id == messageId }),
           let localMessage = roomMessages[safe: messageIndex],
           localMessage.read == false {
            // ローカルのMessageを更新
            roomMessages[messageIndex].read = true
            // UIに反映
            let messageID = message.id
            var snapshot = dataSource.snapshot()
            snapshot.reconfigureItems([messageID])
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    private func messageRoomStatusUpdate(statusFlg: Bool, saveTextFlg: Bool = false, saveText: String = "") {
        
        guard let currentUID = GlobalVar.shared.loginUser?.uid else { return }
        guard let roomID = GlobalVar.shared.specificRoom?.document_id else { return }
        
        let isNotMessageRoom = (GlobalVar.shared.thisClassName != "MessageRoomView")
        let isNotMessageRoomID = (roomID != room?.document_id)
        let isNotSpecificRoom = (isNotMessageRoom || isNotMessageRoomID)
        if isNotSpecificRoom { return }
        
        let db = Firestore.firestore()
        
        var updateRoomData = ["unread_\(currentUID)": 0] as [String:Any]
        
        if statusFlg { // ルームオンライン状態の場合
            updateRoomData["is_room_opened_\(currentUID)"] = true
            updateRoomData["online_user"] = FieldValue.arrayUnion([currentUID])
        } else { // ルームオフライン状態の場合
            updateRoomData["online_user"] = FieldValue.arrayRemove([currentUID])
        }
        if saveTextFlg { // テキスト状態を保存する場合
            updateRoomData["send_message_\(currentUID)"] = saveText
        }
        
        db.collection("rooms").document(roomID).updateData(updateRoomData)
    }
    
    private func messageUnreadID() {
        
        guard let loginUser = GlobalVar.shared.loginUser else { return }
        guard let roomID = room?.document_id else { return }
        
        let loginUID = loginUser.uid
        
        var unreadIDs: [String:String] = [:]
        
        if let loginUserRoom = GlobalVar.shared.loginUser?.rooms.first(where: { $0.document_id == roomID }) {
            unreadIDs = loginUserRoom.unread_ids
            unreadIDs[loginUID] = ""
        }
        
        db.collection("rooms").document(roomID).updateData(["unread_ids": unreadIDs])
    }
    
    private func messageRead(force: Bool = true) {
        
        let isNotMessageRoom = (GlobalVar.shared.thisClassName != "MessageRoomView")
        let isNotMessageRoomID = (GlobalVar.shared.specificRoom?.document_id != room?.document_id)
        let isNotSpecificRoom = (isNotMessageRoom || isNotMessageRoomID)
        let isNotRead = (force == false && isNotSpecificRoom)
        if isNotRead { return }
        
        guard let roomID = room?.document_id else { return }
        guard let partnerUser = room?.partnerUser else { return }
        
        let partnerUID = partnerUser.uid
        
        db.collection("rooms").document(roomID).collection("messages").whereField("creator", isEqualTo: partnerUID).whereField("read", isEqualTo: false).getDocuments { [weak self] (messageSnapshots, err) in
            guard let weakSelf = self else { return }
            if let err = err { print("メッセージ情報の取得失敗: \(err)"); return }
            guard let messageDocuments = messageSnapshots?.documents else { return }
            
            let batch = weakSelf.db.batch()
            messageDocuments.forEach { messageDocument in
                let messageID = messageDocument.documentID
                let messageRef = weakSelf.db.collection("rooms").document(roomID).collection("messages").document(messageID)
                batch.updateData(["read": true], forDocument: messageRef)
            }
            
            batch.commit() { err in
                if let err = err {
                    print("既読をつけられませんでした。Error writing batch \(err)")
                } else {
                    print("全てに既読をつけました。Batch write succeeded.")
                }
            }
        }
    }
    
    private func hideLoadingLabelAnimationAndUpdateFlug() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            self.loadingLabel.alpha = 0
        } completion: { _ in
            self.messageCollectionView.isScrollEnabled = true
            self.isFetchPastMessages = true
            self.loadingLabel.isHidden = true
            self.loadingLabel.alpha = 0.7
        }
    }
}

// メッセージ関連 --- メッセージ送信 ---
extension MessageRoomView {
    
    private func getSendMessageModel(
        text: String,
        inputType: MessageInputType,
        messageType: CustomMessageType,
        sourceType: UIImagePickerController.SourceType?,
        imageUrls: [String]?,
        messageId: String,
        replyMessageId: String? = nil,
        replyMessageText: String? = nil,
        replyMessageCreator: String? = nil,
        replyMessageImageUrls: [String]? = nil,
        replyMessageType: CustomMessageType? = nil
    ) -> MessageSendModel {
        
        let model = MessageSendModel(
            text: text,
            inputType: inputType,
            messageType: messageType,
            sourceType: sourceType,
            imageUrls: imageUrls,
            sticker: nil,
            stickerIdentifier: nil,
            messageId: messageId,
            replyMessageId: replyMessageId,
            replyMessageText: replyMessageText,
            replyMessageCreator: replyMessageCreator,
            replyMessageImageUrls: replyMessageImageUrls,
            replyMessageType: replyMessageType
        )
        
        return model
    }
    
    private func sendMessageToFirestore(_ model: MessageSendModel) {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        guard let roomId = room?.document_id else {
            return
        }
        guard let partnerUser = room?.partnerUser else {
            return
        }
        let messageId = model.messageId
        let members = [loginUser.uid, partnerUser.uid]
        let sendTime = Timestamp()
        let messageType = model.messageType
        let replyMessageId = model.replyMessageId
        let replyMessageText = model.replyMessageText
        let replyMessageCreator = model.replyMessageCreator
        let replyMessageImageUrls = model.replyMessageImageUrls
        let replyMessageType = model.replyMessageType
        let messageText = model.text
        
        // Firestoreとの通信前にUIを更新することでスピーディーなUXを実現
        addLocalMessages(
            messageId: messageId,
            messageText: messageText,
            type: messageType,
            members: members,
            sendTime: sendTime,
            imageUrls: model.imageUrls,
            sticker: model.sticker,
            replyMessageId: replyMessageId,
            replyMessageText: replyMessageText,
            replyMessageCreator: replyMessageCreator,
            replyMessageImageUrls: replyMessageImageUrls,
            replyMessageType: replyMessageType
        )
        
        var messageData: [String: Any] = [
            "room_id": roomId,
            "message_id": messageId,
            "text": model.text,
            "photos": model.imageUrls as Any,
            "sticker_identifier": model.stickerIdentifier as Any,
            "read": false,
            "members": members,
            "creator": loginUser.uid,
            "type": model.messageType.rawValue as Any,
            "unread_flg": true,
            "calc_unread_flg": true,
            "created_at": sendTime,
            "updated_at": sendTime
        ]
        if let _replyMessageId = replyMessageId, let _replyMessageText = replyMessageText, let _replyMessageCreator = replyMessageCreator, let _replyMessageImageUrls = replyMessageImageUrls, let _replyMessageType = replyMessageType {
            messageData["reply_message_id"] = _replyMessageId
            messageData["reply_message_text"] = _replyMessageText
            messageData["reply_message_creator"] = _replyMessageCreator
            messageData["reply_message_image_urls"] = _replyMessageImageUrls
            messageData["reply_message_type"] = _replyMessageType.rawValue
        }
        
        db.collection("rooms").document(roomId).collection("messages").document(messageId).setData(messageData)
        
        var partnerUnreadID: String = ""
        var unreadIDs: [String:String] = [:]
        
        if let loginUserRoom = GlobalVar.shared.loginUser?.rooms.first(where: { $0.document_id == roomId }) {
            partnerUnreadID = loginUserRoom.unread_ids[partnerUser.uid] ?? ""
            unreadIDs[loginUser.uid] = ""
            unreadIDs[partnerUser.uid] = (partnerUnreadID.isEmpty ? messageId : partnerUnreadID)
        }
        
        let removedUser: [String] = []
        let latestMessageData:[String: Any] = [
            "latest_message_id": messageId,
            "latest_message": model.text,
            "latest_sender": loginUser.uid,
            "removed_user": removedUser,
            "unread_\(loginUser.uid)": 0,
            "unread_ids": unreadIDs,
            "unread_\(partnerUser.uid)": FieldValue.increment(Int64(1)),
            "creator": loginUser.uid,
            "updated_at": sendTime
        ]
        db.collection("rooms").document(roomId).updateData(latestMessageData)
        
        var category = UserNoticeType.messageText.rawValue
        
        switch messageType {
        case .image:
            category = UserNoticeType.messageImage.rawValue
            break
        case .sticker:
            category = UserNoticeType.messageStamp.rawValue
            break
        case .reply:
            let stickerID = model.stickerIdentifier ?? ""
            let replySticker = stickerID.count > 0
            if replySticker {
                category = UserNoticeType.messageReplyStamp.rawValue
            }
            break
        default:
            break
        }
        registNotificationEachUser(
            category: category,
            creator: loginUser.uid,
            members: members,
            roomID: roomId,
            messageID: messageId
        )
        
        let logEventData: [String: Any] = [
            "room_id": roomId,
            "message_id": messageId,
            "text": model.text as Any,
            "target": partnerUser.uid
        ]
        
        switch model.inputType {
        case .talk:
            Log.event(name: "sendMessageFromTalkView", logEventData: logEventData)
        case .camera:
            if model.sourceType == .photoLibrary {
                Log.event(name: "sendMessageFromPhotoLibraryInput", logEventData: logEventData)
            } else if model.sourceType == .camera {
                Log.event(name: "sendMessageFromCameraInput", logEventData: logEventData)
            }
        case .message:
            Log.event(name: "sendMessageFromMessageInput", logEventData: logEventData)
        case .reply:
            Log.event(name: "sendMessageFromMessageReply", logEventData: logEventData)
        case .sticker:
            Log.event(name: "sendMessageFromMessageSticker", logEventData: logEventData)
        }
        
#if PROD
        Task {
            let _ = try await callFunctionEnabled(loginUser, partnerUser: partnerUser, rallyNum: 1)
            if room?.is_auto_matchig == false {
                reviewAlert(alertType: "message")
            }
        }
#endif
    }
    
    private func addLocalMessages(
        messageId: String,
        messageText: String,
        type: CustomMessageType,
        members: [String],
        sendTime: Timestamp,
        imageUrls: [String]?,
        sticker: UIImage?,
        replyMessageId: String? = nil,
        replyMessageText: String? = nil,
        replyMessageCreator: String? = nil,
        replyMessageImageUrls: [String]? = nil,
        replyMessageType: CustomMessageType? = nil
    ) {
        
        guard let loginUser = GlobalVar.shared.loginUser, let roomId = room?.document_id else { return }
        
        // すでに存在している場合はスキップ
        if roomMessages.firstIndex(where: {$0.document_id == messageId}) != nil {
            return
        }
        
        var message: Message?
        let loginUID = loginUser.uid
        
        switch type {
        case .image:
            guard let _imageUrls = imageUrls else { return }
            message = Message(
                room_id: roomId,
                text: "画像が送信されました。",
                photos: _imageUrls,
                sticker: sticker,
                stickerIdentifier: "",
                read: false,
                creator: loginUID,
                members: members,
                type: .image,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: replyMessageId,
                reply_message_text: replyMessageText,
                reply_message_creator: replyMessageCreator,
                reply_message_image_urls: replyMessageImageUrls,
                reply_message_type: replyMessageType,
                document_id: messageId
            )
        case .sticker:
            message = Message(
                room_id: roomId,
                text: "スタンプが送信されました。",
                photos: imageUrls ?? [],
                sticker: sticker,
                stickerIdentifier: "",
                read: false,
                creator: loginUID,
                members: members,
                type: .sticker,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: replyMessageId,
                reply_message_text: replyMessageText,
                reply_message_creator: replyMessageCreator,
                reply_message_image_urls: replyMessageImageUrls,
                reply_message_type: replyMessageType,
                document_id: messageId
            )
        case .text:
            message = Message(
                room_id: roomId,
                text: messageText,
                photos: imageUrls ?? [],
                sticker: sticker,
                stickerIdentifier: "",
                read: false,
                creator: loginUID,
                members: members,
                type: .text,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: replyMessageId,
                reply_message_text: replyMessageText,
                reply_message_creator: replyMessageCreator,
                reply_message_image_urls: replyMessageImageUrls,
                reply_message_type: replyMessageType,
                document_id: messageId
            )
            /*
        case .movie:
            guard let _imageUrls = imageUrls else {
                return
            }
            message = Message(
                room_id: roomId,
                text: "動画が送信されました。",
                photos: _imageUrls,
                sticker: sticker,
                read: false,
                creator: loginUID,
                members: members,
                type: .image,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: replyMessageId,
                reply_message_text: replyMessageText,
                reply_message_creator: replyMessageCreator,
                reply_message_image_urls: replyMessageImageUrls,
                reply_message_type: replyMessageType,
                document_id: messageId
            )
             */
        case .reply:
            guard let _replyMessageId = replyMessageId,
                  let _replyMessageText = replyMessageText,
                  let _replyMessageCreator = replyMessageCreator,
                  let _replyMessageImageUrls = replyMessageImageUrls,
                  let _replyMessageType = replyMessageType
            else {
                return
            }
            message = Message(
                room_id: roomId,
                text: messageText,
                photos: imageUrls ?? [],
                sticker: sticker,
                stickerIdentifier: "",
                read: false,
                creator: loginUID,
                members: members,
                type: .reply,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: _replyMessageId,
                reply_message_text: _replyMessageText,
                reply_message_creator: _replyMessageCreator,
                reply_message_image_urls: _replyMessageImageUrls,
                reply_message_type: _replyMessageType,
                document_id: messageId
            )
        case .talk:
            message = Message(
                room_id: roomId,
                text: messageText,
                photos: imageUrls ?? [],
                sticker: sticker,
                stickerIdentifier: "",
                read: false,
                creator: loginUID,
                members: members,
                type: .text,
                created_at: sendTime,
                updated_at: sendTime,
                is_deleted: false,
                reactionEmoji: "",
                reply_message_id: replyMessageId,
                reply_message_text: replyMessageText,
                reply_message_creator: replyMessageCreator,
                reply_message_image_urls: replyMessageImageUrls,
                reply_message_type: replyMessageType,
                document_id: messageId
            )
        }
        
        guard let message else { return }
        guard message.document_id != nil else { fatalError("document_id is nil") }
        let messageID = message.id
        
        self.roomMessages.append(message)
        
        var snapshot = dataSource.snapshot()
        snapshot.appendItems([messageID], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true) {
            self.scrollToBottom()
            self.messageSending = false
        }
    }
    
    private func setMessageStorage(_ text: String?) {
        let user = GlobalVar.shared.loginUser
        let rooms = user?.rooms
        
        if let index = rooms?.firstIndex(where: { $0.document_id == room?.document_id }) {
            rooms?[index].send_message = text
            textView.text = text
        }
    }
}


// MARK: - Media

extension MessageRoomView: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate {
    
    private func presentPicker() {
        self.textView.resignFirstResponder()
        
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .any(of: [.images])
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .ordered
        configuration.selectionLimit = 5
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    private func presentCamera() {
        self.textView.resignFirstResponder()
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.isEmpty {
            picker.dismiss(animated: true)
            return
        }
        
        let alert = UIAlertController(title: "確認", message: "選択した画像を送信しますか？", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "キャンセル", style: .cancel)
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            let imageItemProviders = results.compactMap { $0.itemProvider }.filter { $0.canLoadObject(ofClass: UIImage.self)}
            
            guard !imageItemProviders.isEmpty else {
                self.customAlert(alertType: .emptyFile)
                picker.dismiss(animated: true)
                return
            }
            Task {
                await MainActor.run {
                    self.showLoadingView(self.loadingView)
                }
                
                await self.dealWithImage(picker, itemProviders: imageItemProviders)
                
                await MainActor.run {
                    self.loadingView.removeFromSuperview()
                    self.scrollToBottom()
                    picker.dismiss(animated: true)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(ok)
        
        picker.present(alert, animated: true)
    }
    
    /// UIImageへの変換・アップロード
    private func dealWithImage(_ picker: PHPickerViewController, itemProviders: [NSItemProvider]) async {
        var selectPickerImages = [UIImage]()
        
        await itemProviders.asyncForEach { itemProvider in
            do {
                let itemProviderImage = try await itemProvider.loadObject(ofClass: UIImage.self)
                if let image = itemProviderImage as? UIImage {
                    if let resizedImage = image.resized(size: CGSize(width: 400, height: 400)) {
                        selectPickerImages.append(resizedImage)
                    } else {
                        selectPickerImages.append(image)
                    }
                }
            } catch {
                print("Failure to get Image with", error)
                picker.dismiss(animated: true)
                self.customAlert(alertType: .notReadFile)
                return
            }
        }
        
        if selectPickerImages.isEmpty {
            picker.dismiss(animated: true)
            self.customAlert(alertType: .emptyFile)
            return
        }
        
        guard let roomId = self.room?.document_id else {
            picker.dismiss(animated: true)
            self.customAlert(alertType: .nonDocumentID)
            return
        }
        
        self.uploadImageStrage(roomId, images: selectPickerImages) { imageUrls in
            let model = self.getSendMessageModel(
                text: "画像が送信されました",
                inputType: .camera,
                messageType: .image,
                sourceType: .photoLibrary,
                imageUrls: imageUrls,
                messageId: UUID().uuidString
            )
            self.sendMessageToFirestore(model)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var images: [UIImage] = []
        
        initTextView()
        
        if !textView.isFirstResponder {
            keyboardWillHide(nil)
        }
        
        picker.dismiss(animated: true)
        
        guard let roomId = room?.document_id else {
            customAlert(alertType: .nonDocumentID)
            return
        }
        
        showLoadingView(loadingView)
        
        if let image = info[.originalImage] as? UIImage {
            let size = CGSize(width: 400, height: 400)
            if let resizedImage = image.resized(size: size) {
                images.append(resizedImage)
            } else {
                images.append(image)
            }
        }
        
        guard !images.isEmpty else {
            print(#function, "画像が追加されていません")
            self.loadingView.removeFromSuperview()
            return
        }
        
        uploadImageStrage(roomId, images: images) { imageUrls in
            let model = self.getSendMessageModel(
                text: "画像が送信されました",
                inputType: .camera,
                messageType: .image,
                sourceType: picker.sourceType,
                imageUrls: imageUrls,
                messageId: UUID().uuidString
            )
            self.sendMessageToFirestore(model)
            self.loadingView.removeFromSuperview()
        }
    }
    
    private func uploadImageStrage(_ roomId: String, images: [UIImage], completion: @escaping ([String]) -> Void) {
        let referenceName = "rooms/\(roomId)"
        let folderName = "messages"
        let messageId = UUID().uuidString
        var imageUrls: [String] = []
        
        if images.count == 0 {
            completion(imageUrls)
        }
        
        images.enumerated().forEach { index, image in
            let fileId = messageId + "_" + String(index)
            let fileName = "img_\(fileId).jpg"
            let metadata = [
                "type": "message",
                "room_id": roomId,
                "message_id": messageId,
                "file_id": fileId
            ]
            
            firebaseController.uploadImageToFireStorage(
                image: image,
                referenceName: referenceName,
                folderName: folderName,
                fileName: fileName,
                customMetadata: metadata,
                completion: { result in
                    
                    imageUrls.append(result)
                    
                    if imageUrls.count == images.count {
                        imageUrls.sort(by: { $0 < $1 })
                        completion(imageUrls)
                    }
                }
            )
        }
    }
    
    private func customAlert(alertType: SendMessageAlertType) {
        
        loadingView.removeFromSuperview()
        
        switch alertType {
        case .nonDocumentID:
            let title = "送信失敗"
            let message = "送信対象のルームが存在しないため送信できませんでした。"
            alert(title: title, message: message, actiontitle: "OK")
            break
        case .overFileSize:
            let title = "送信失敗"
            let message = "送信するファイルサイズを200MB以下にして送信してください。"
            alert(title: title, message: message, actiontitle: "OK")
            break
        case .emptyFile:
            let title = "送信失敗"
            let message = "送信するファイルが適切に送信できませんでした。再送信をお願いします。"
            alert(title: title, message: message, actiontitle: "OK")
            break
        case .notReadFile:
            let title = "送信失敗"
            let message = "送信するファイルが読み込めませんでした"
            alert(title: title, message: message, actiontitle: "OK")
            break
        }
    }
}


// MARK: - Unsend & Reaction
extension MessageRoomView {
    
    /// 編集されたメッセージが送信取り消しされたかを判定し、された場合はプロパティの更新とUIの再構築を行う。
    private func unsendRoomMessage(messageDocument: DocumentChange) {
        let messageDocument = messageDocument.document
        let message = Message(document: messageDocument)
        let messageID = message.id
        // is_deletedで判定
        guard message.is_deleted, let messageId = message.document_id else { return }
        
        if let unsendedMessageIndex = roomMessages.firstIndex(where: {$0.document_id == messageId}), let localMessage = roomMessages[safe: unsendedMessageIndex] {
            // ローカルのMessageを更新
            localMessage.is_deleted = true
            roomMessages[unsendedMessageIndex] = localMessage
            // UIを更新
            var snapshot = self.dataSource.snapshot()
            snapshot.reloadItems([messageID])
            self.dataSource.apply(snapshot, animatingDifferences: true)
            // latest_messageを更新
            self.updateLatestMessage(roomId: message.room_id, unsendedMessageId: messageId)
        }
    }
    
    /// 送信取り消しがあった場合、最新のメッセージの情報を更新する
    private func updateLatestMessage(roomId: String, unsendedMessageId: String) {
        // 送信取り消ししたメッセージが、元々送信取り消しされていない最新のメッセージだった場合のみlatest_messageを更新する。
        guard let unsendedMessageCreatedAt = roomMessages.first(where: { $0.document_id == unsendedMessageId })?.created_at,
              roomMessages.filter({ $0.created_at.dateValue() > unsendedMessageCreatedAt.dateValue() && $0.is_deleted == false }).isEmpty else { return }
        
        /* (A) 更新できる最新のメッセージ情報がある場合。roomMessages内に、message.is_deleted == falseが存在する場合 */
        if let lastMessage = roomMessages.last(where: { $0.is_deleted == false }),
           let latestMessageID = lastMessage.document_id {
            
            let latestMessageSender = lastMessage.creator
            let latestMessageUpdatedAt = lastMessage.created_at
            
            switch lastMessage.type {
            case .text:
                let latestMessage = lastMessage.text
                
                let latestMessageData = [
                    "latest_message_id": latestMessageID,
                    "latest_message": latestMessage,
                    "latest_sender": latestMessageSender,
                    "updated_at": latestMessageUpdatedAt
                ] as [String : Any]
                db.collection("rooms").document(roomId).updateData(latestMessageData)
                
            case.image:
                let latestMessage = "画像が送信されました"
                
                let latestMessageData = [
                    "latest_message_id": latestMessageID,
                    "latest_message": latestMessage,
                    "latest_sender": latestMessageSender,
                    "updated_at": latestMessageUpdatedAt
                ] as [String : Any]
                db.collection("rooms").document(roomId).updateData(latestMessageData)
                
            case.sticker:
                let latestMessage = "スタンプが送信されました"
                
                let latestMessageData = [
                    "latest_message_id": latestMessageID,
                    "latest_message": latestMessage,
                    "latest_sender": latestMessageSender,
                    "updated_at": latestMessageUpdatedAt
                ] as [String : Any]
                db.collection("rooms").document(roomId).updateData(latestMessageData)
                
            default:
                break
            }
        }
        /* (B) 更新できる最新のメッセージ情報がない場合。roomMessages内に、message.is_deleted == falseが存在しない場合 */
        else {
            guard roomMessages.filter({ return $0.is_deleted == false }).isEmpty, let room else { return }
            // latest_message関連の情報はルーム作成時の初期状態に戻す
            let latestMessageData = [
                "latest_message_id": "",
                "latest_message": "",
                "latest_sender": "",
                "updated_at": room.created_at
            ] as [String : Any]
            db.collection("rooms").document(roomId).updateData(latestMessageData)
        }
    }
    
    /// 編集されたメッセージのリアクションが変更されたかを判定し、された場合はプロパティの更新とUIの再構築を行う。
    private func updateMessageReaction(messageDocument: DocumentChange) {
        let messageDocument = messageDocument.document
        let message = Message(document: messageDocument)
        let messageID = message.id
        // Messageのdocument_idから該当のメッセージを検索し、更新したMessageと入れ替える
        if let messageId = message.document_id,
           let updateMessageIndex = roomMessages.firstIndex(where: {$0.document_id == messageId}),
           let localMessage = roomMessages[safe: updateMessageIndex] {
            // ローカルに存在する変更前と同じ値ならここでスキップ
            if localMessage.reactionEmoji == message.reactionEmoji { return }
            // ローカルのMessageを更新
            localMessage.reactionEmoji = message.reactionEmoji
            roomMessages[updateMessageIndex] = localMessage
            // UIを更新
            var snapshot = self.dataSource.snapshot()
            snapshot.reconfigureItems([messageID])
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}

// コピー関連
extension MessageRoomView {
    
    private func copy(indexPath: IndexPath) {
        guard let selectedMessage = getSelectedMessage(actionType: .copy, indexPath: indexPath) else {
            return
        }
        let pasteBoard = UIPasteboard.general
        switch selectedMessage.type {
        case .text, .reply:
            pasteBoard.string = selectedMessage.text
        case .image, .talk, .sticker:
            break
        }
        return
    }
}

//MARK: - Message Reply

extension MessageRoomView: MessageInputViewReplyDelegate {
    // リプレイプレビューを閉じる
    func closeReplyPreview() {
        setReplyPreview(active: false)
    }
    
    private func showReplyPreview(indexPath: IndexPath) {
        
        guard let room = room,  let selectedMessage = getSelectedMessage(actionType: .reply, indexPath: indexPath) else { return }
        let isReplySticker = (selectedMessage.type == .reply && !selectedMessage.photos.isEmpty)
        
        messageInputView.showReplyPreview(room: room, roomMessage: selectedMessage)
        
        replyIsSelected = true
        replyMessageID = selectedMessage.document_id
        replyMessageText = selectedMessage.text
        replyMessageCreator = selectedMessage.creator
        replyMessageImageUrls = selectedMessage.photos
        replyMessageType = isReplySticker ? .sticker : selectedMessage.type
        
        removeMessageRoomTypingListener()
    }
    /// messageReplyPreviewの表示・非表示を行う
    private func setReplyPreview(active: Bool) {
        messageInputView.setReplyPreview(active: active)
        replyIsSelected = active
        replyMessageID = (active == true ? replyMessageID : nil)
        replyMessageText = (active == true ? replyMessageText : nil)
        replyMessageCreator = (active == true ? replyMessageCreator : nil)
        replyMessageImageUrls = (active == true ? replyMessageImageUrls : nil)
        replyMessageType = (active == true ? replyMessageType : nil)
        
        if !active && GlobalVar.shared.messageRoomTypingListener == nil {
            observeTypingState()
        }
    }
    // リプライ機能でのエラーアラートを表示する
    private func showReplyErrorAlert(errorCase: Int) {
        let message = (errorCase == 0) ? "正常に処理できませんでした。\n運営にお問い合わせください。" : "スタンプのアップロードに失敗しました。\nアプリを再起動して再度実行をしてください。"
        let alert = UIAlertController(title: "スタンプ送信エラー", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { [weak self] action in
            if errorCase == 0 { return }
            guard let weakSelf = self else { return }
            weakSelf.roomMessages.removeLast()
            weakSelf.messageCollectionView.reloadData()
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

// MARK: - MessageNoticeViewDelegate

extension MessageRoomView: MessageNoticeViewDelegate {

    func tappedNoticePreview() {
        scrollToBottom(animated: true)
    }

    private func setNotificationView(_ message: Message) {
        if message.creator != GlobalVar.shared.loginUser?.uid {
            messageInputView.setNotificationView(message)
            messageInputView.noticePreview.isHidden = false
        }
    }
}

// MARK: - MessagePopMenuViewControllerDelegate
extension MessageRoomView: UIPopoverPresentationControllerDelegate, MessagePopMenuViewControllerDelegate {
    
    /// ロングタップされたセルの情報を元に、Popoverを表示する
    private func presentPopover(indexPath: IndexPath, sourceRect: CGRect, type: CustomMessageType, isLoginUser: Bool) {
        guard let currentCell = messageCollectionView.cellForItem(at: indexPath) else {
            initPopoverItem()
            return
        }
        self.popoverItem.indexPath = indexPath
        let minCellWidth = 50.0 // 任意
        // indexPathでのセルの画面上の位置
        var cellPosition: CGRect {
            let point = CGPoint(x: currentCell.frame.origin.x - messageCollectionView.contentOffset.x, y: currentCell.frame.origin.y - messageCollectionView.contentOffset.y)
            let size = currentCell.bounds.size
            return CGRect(x: point.x, y: point.y, width: size.width, height: size.height)
        }
        // 位置・範囲内に存在するかの判定
        let cellSizeIsWithinThreshold = cellPosition.minY >= messageCollectionView.frame.minY && cellPosition.maxY <= messageInputView.frame.minY
        let positionIsWithinThreshold = (cellPosition.minY + sourceRect.minY > messageCollectionView.frame.minY + MessagePopMenuViewController.height) || (cellPosition.maxY < messageInputView.frame.minY - MessagePopMenuViewController.height)
        
        /* (1) セルの大きさが範囲内 */
        if cellSizeIsWithinThreshold {
            if textView.isFirstResponder {
                /* (1-A) キーボードが表示されている */
                if positionIsWithinThreshold {
                    /* (1-A-1) セルの上部 or 下部にPopoverを表示できる */
                    let isUpper = cellPosition.minY <= messageCollectionView.frame.minY + MessagePopMenuViewController.height - sourceRect.minY // 上向きか下向きかを判定
                    
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: isUpper, type: type)
                    }
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = currentCell
                    popMenuVC.popoverPresentationController?.sourceRect = sourceRect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = sourceRect.width > minCellWidth ? (isUpper ? .up : .down) : .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                } else {
                    /* (1-A-2) セルの上部 or 下部にPopoverを表示できない。中央に表示。 */
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: false, type: type)
                    }
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = currentCell
                    popMenuVC.popoverPresentationController?.sourceRect = sourceRect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                }
            } else {
                /* (1-B) キーボードが表示されていない */
                if positionIsWithinThreshold {
                    /* (1-B-1) セルの上部 or 下部にPopoverを表示できる */
                    let isUpper = cellPosition.minY <= messageCollectionView.frame.minY + MessagePopMenuViewController.height - sourceRect.minY // 上向きか下向きかを判定
                    
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: isUpper, type: type)
                    }
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = currentCell
                    popMenuVC.popoverPresentationController?.sourceRect = sourceRect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = sourceRect.width > minCellWidth ? (isUpper ? .up : .down) : .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                } else {
                    /* (1-B-2) セルの上部 or 下部にPopoverを表示できない。中央に表示。 */
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: false, type: type)
                    }
                    let rect = CGRect(x: sourceRect.minX,
                                      y: messageCollectionView.frame.maxY / 2,
                                      width: sourceRect.width,
                                      height: 1.0)
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = self.view
                    popMenuVC.popoverPresentationController?.sourceRect = rect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                }
            }
        } else {
            /* (2) セルの大きさが範囲外 */
            if textView.isFirstResponder, let keyboardFrame {
                /* (2-A) キーボードが表示されている */
                if positionIsWithinThreshold {
                    /* (2-A-1) セルの上部または下部にPopoverを表示できる場合 */
                    let isUpper = cellPosition.minY <= messageCollectionView.frame.minY + MessagePopMenuViewController.height  // 上向きか下向きかを判定
                    
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: isUpper, type: type)
                    }
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = currentCell
                    popMenuVC.popoverPresentationController?.sourceRect = sourceRect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = sourceRect.width > minCellWidth ? (isUpper ? .up : .down) : .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                } else {
                    /* (2-A-2) セルの上部 or 下部にPopoverを表示できない。中央に表示。 */
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: false, type: type)
                    }
                    let rect = CGRect(x: sourceRect.minX,
                                      y: (keyboardFrame.minY - messageCollectionView.frame.minY) / 2,
                                      width: sourceRect.width,
                                      height: 1.0)
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = self.view
                    popMenuVC.popoverPresentationController?.sourceRect = rect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                }
            } else {
                /* (2-B) キーボードが表示されていない */
                let minYThreshold = messageCollectionView.frame.minY
                let maxYThreshold = messageInputView.frame.minY
                let minYIsOutThreshold = cellPosition.minY < minYThreshold + MessagePopMenuViewController.height
                let maxYIsOutThreshold = cellPosition.maxY > maxYThreshold - MessagePopMenuViewController.height
                let isOutThreshold = minYIsOutThreshold && maxYIsOutThreshold
                
                /* (2-B-1) セルの上部または下部にPopoverを表示できる場合 */
                if !isOutThreshold {
                    let isUpper = cellPosition.minY <= messageCollectionView.frame.minY + MessagePopMenuViewController.height - sourceRect.minY // 上向きか下向きかを判定
                    
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: isUpper, type: type)
                    }
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = currentCell
                    popMenuVC.popoverPresentationController?.sourceRect = sourceRect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = isUpper ? .up : .down
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                } else {
                    /* (2-B-2) セルの上部 or 下部にPopoverを表示できない。中央に表示。 */
                    let storyboard = UIStoryboard(name: MessagePopMenuViewController.storyboardName, bundle: nil)
                    let popMenuVC = storyboard.instantiateViewController(identifier: MessagePopMenuViewController.storybaordId) { coder in
                        return MessagePopMenuViewController(coder: coder, isLoginUser: isLoginUser, isUpper: false, type: type)
                    }
                    let rect = CGRect(x: sourceRect.minX,
                                      y: messageCollectionView.frame.maxY / 2,
                                      width: sourceRect.width,
                                      height: 1.0)
                    popMenuVC.delegate = self
                    popMenuVC.modalPresentationStyle = .popover
                    popMenuVC.popoverPresentationController?.sourceView = self.view
                    popMenuVC.popoverPresentationController?.sourceRect = rect
                    popMenuVC.popoverPresentationController?.permittedArrowDirections = .unknown
                    popMenuVC.popoverPresentationController?.popoverBackgroundViewClass = MessagePopoverBackgroundView.self
                    popMenuVC.popoverPresentationController?.delegate = self // iPhone で Popover を表示するために必要
                    
                    present(popMenuVC, animated: true)
                }
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    private func initPopoverItem() {
        popoverItem.indexPath = nil
        popoverItem.image = nil
    }
    
    // MARK: Popover各ボタンのタップアクション
    func replyButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController) {
        if let indexPath = popoverItem.indexPath {
            showReplyPreview(indexPath: indexPath)
        }
        messagePopMenuViewController.dismiss(animated: true)
    }
    
    func copyButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController) {
        if let indexPath = popoverItem.indexPath {
            copy(indexPath: indexPath)
        }
        messagePopMenuViewController.dismiss(animated: true)
    }
    
    func stickerButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController) {
        showStickerInputView()
        messagePopMenuViewController.dismiss(animated: true)
    }
    
    func showImageButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController) {
        messagePopMenuViewController.dismiss(animated: true)
        if let image = popoverItem.image {
            moveImageDetail(image: image)
        }
        initPopoverItem()
    }
    
    func unsendButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController) {
        guard let indexPath = popoverItem.indexPath, let selectedMessage = getSelectedMessage(actionType: .unsend, indexPath: indexPath) else {
            initPopoverItem()
            messagePopMenuViewController.dismiss(animated: true)
            return
        }
        // Firestoreへメッセージ情報の更新を行う
        guard let messageId = selectedMessage.document_id, let roomId = room?.document_id, let unsendMessageIndex = roomMessages.firstIndex(where: { $0.document_id == messageId }) else {
            initPopoverItem()
            messagePopMenuViewController.dismiss(animated: true)
            return
        }
        // メッセージの送信取り消しフラグを更新
        db.collection("rooms").document(roomId).collection("messages").document(messageId).updateData(["is_deleted" : true])
        roomMessages[safe: unsendMessageIndex]?.is_deleted = true
        
        // 送信取り消ししたメッセージが未読の場合は相手の未読数も更新
        let unreadCount = roomMessages.filter({
            $0.creator == GlobalVar.shared.loginUser?.uid && $0.read == false && $0.is_deleted == false
        }).count
        if selectedMessage.read == false, let partnerUserUid = room?.partnerUser?.uid, unreadCount >= 0, unreadCount < roomMessages.count {
            db.collection("rooms").document(roomId).updateData(["unread_\(partnerUserUid)": unreadCount])
        }
        initPopoverItem()
        messagePopMenuViewController.dismiss(animated: true)
    }
    
    func reactionButtonPressed(_ messagePopMenuViewController: MessagePopMenuViewController, didSelectedReaction: String) {
        guard let indexPath = popoverItem.indexPath, let selectedMessage = getSelectedMessage(actionType: .reaction, indexPath: indexPath), !didSelectedReaction.isEmpty else {
            initPopoverItem()
            messagePopMenuViewController.dismiss(animated: true)
            return
        }
        // メッセージの取得
        let section = indexPath.section
        let index = indexPath.row
        
        reactionIndexPath = IndexPath(row: index, section: section)
        
        if let messageId = selectedMessage.document_id, let roomId = room?.document_id {
            
            let sameReaction = (selectedMessage.reactionEmoji == didSelectedReaction)
            // 同じリアクションを選択した場合は取り消す
            let uploadReaction = (sameReaction == true ? "" : didSelectedReaction)
            // Firestoreへメッセージ情報の更新を行う
            db.collection("rooms").document(roomId).collection("messages").document(messageId).updateData(["reaction": uploadReaction])
            // リアクションをつけた場合 (リアクションの取り消しは処理させない)
            if sameReaction == false {
                let messageCreator = selectedMessage.creator
                let loginUID = GlobalVar.shared.loginUser?.uid ?? ""
                let members = room?.members ?? [String]()
                let category = UserNoticeType.messageReaction.rawValue
                
                let isOtherMessage = (messageCreator != loginUID)
                if isOtherMessage {
                    registNotificationEachUser(
                        category: category,
                        creator: loginUID,
                        members: members,
                        roomID: roomId,
                        messageID: messageId
                    )
                }
            }
        }
        initPopoverItem()
        messagePopMenuViewController.dismiss(animated: true)
    }
    
    private func getSelectedMessage(actionType: buttonActionType, indexPath: IndexPath) -> Message? {
        
        let section = indexPath.section
        let index = indexPath.row
        
        switch actionType {
        case .reaction:
            reactionIndexPath = IndexPath(row: index, section: section)
        default:
            break
        }
        
        return roomMessages[safe: indexPath.row]
    }
}

// MARK: - Typing Indicator
extension MessageRoomView {
    
    func removeMessageRoomTypingListener() {
        GlobalVar.shared.messageRoomTypingListener?.remove()
        GlobalVar.shared.messageRoomTypingListener = nil
        changeTypingIndicatorState(false)
    }
    /// 特定のRoomの is_typing_user.uid: Bool'を更新
    private func updateTypingState(isTyping: Bool) {
        
        guard let loginUserId = GlobalVar.shared.loginUser?.uid else { return }
        guard let roomId = room?.document_id else { return }
        
        db.collection("rooms").document(roomId).updateData(["is_typing_\(loginUserId)": isTyping]) { error in
            if let _error = error { print("メッセージの入力状態の更新に失敗\(_error)") }
        }
    }
    // 現在のRoomの更新を監視し、相手のユーザーが入力中かを判断する
    private func observeTypingState() {
        
        guard let roomId = room?.document_id else { return }
        
        removeMessageRoomTypingListener()
        
        GlobalVar.shared.messageRoomTypingListener = db.collection("rooms").document(roomId).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self else { return }
            if let err = error { print("Room情報の監視に失敗: \(err)"); return }
            guard let _querySnapshot = querySnapshot,
                  let partnerUserId = room?.partnerUser?.uid,
                  let partnerUserIsTyping = _querySnapshot.data()?["is_typing_\(partnerUserId)"] as? Bool else { return }
            changeTypingIndicatorState(partnerUserIsTyping)
        }
    }
    // 相手のユーザーが入力中の場合はTypingIndicatorViewを表示し、入力していない場合は非表示にする
    private func changeTypingIndicatorState(_ partnerUserIsTyping: Bool) {
        if partnerUserIsTyping {
            UIView.animate(withDuration: 0.3, animations: {
                self.typingIndicatorView?.alpha = 1.0
            }) {_ in
                self.typingIndicatorView?.indicatorView.startAnimating()
                self.typingIndicatorView?.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.typingIndicatorView?.alpha = 0.0
            }) {_ in
                self.typingIndicatorView?.isHidden = true
                self.typingIndicatorView?.indicatorView.stopAnimating()
            }
        }
    }
}
