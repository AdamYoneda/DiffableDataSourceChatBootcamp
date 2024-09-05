//
//  MessageListViewController.swift
//  ChatLikeSampler
//
//  Created by Daichi Tsuchiya on 2021/10/21.
//

import UIKit
import FirebaseFirestore
import Typesense

final class MessageListViewController: UIBaseViewController {

    @IBOutlet weak var messageListTableView: UITableView!
    
    static let storyboardName = "MessageListViewController"
    static let identifier = "MessageListViewController"
    static var noteIconView: NoteIconView? = nil
    
    private let defaultRowsInSection = 0
    private let defaultCellheight = 0.0
    private let indicatorView = UIView(frame: UIScreen.main.bounds)
    private var isIndicatorShowed = false
    private var isFetchPastMessageList = true
    private var beforeScrollContentOffsetY = CGFloat(0)
    private let userDefaults = UserDefaults.standard
    
    private var indicatorStatus: IndicatorStatus = .hide {
        didSet {
            switch indicatorStatus {
            case .show:
                if isIndicatorShowed {
                    return
                }
                showLoadingView(indicatorView)
                isIndicatorShowed = true
            case .hide:
                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.1) {
                    self.indicatorView.removeFromSuperview()
                    self.isIndicatorShowed = false
                }
            }
        }
    }
    
    private enum IndicatorStatus {
        case show
        case hide
    }
    
    private enum Section: Int {
        case header = 0
        case newMatch = 1
        case pinRoomList = 2
        case roomList = 3
    }
    
    //MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.setNavigationBarColor(.white)
            self.sortRoomsForPinnedAction()
            self.setUpRefreshControl()
            self.prefetcher.isPaused = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initLatestRoomIdAndLatestUnReadCount()
        showTalkGuideDisplayRanking()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.indicatorStatus = .hide
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeRefreshControl()
        resetLatestRoomIdAndLatestUnReadCount()
        if messageListTableView != nil {
            GlobalVar.shared.messageListTableView = messageListTableView
        }
        prefetcher.isPaused = true
        indicatorStatus = .hide
    }
    
    private func setUp() {
        indicatorStatus = .show
        setUpNavigationBar()
        setUpTableView()
        setUpTableViewCell()
        setUpNotification()
        playTutorial(key: "isShowedMessageTutorial", type: .message)
    }
    
    private func setUpNavigationBar() {
        // ナビゲーションバーを表示する
        navigationController?.setNavigationBarHidden(false, animated: true)
        // ナビゲーションの戻るボタンを消す
        navigationItem.setHidesBackButton(true, animated: true)
        // ナビゲーションバーの右側にボタンを設定
        let image = UIImage(systemName: "questionmark.circle")
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action:#selector(moveFriendEmoji))
        navigationItem.rightBarButtonItem = button
        navigationItem.rightBarButtonItem?.tintColor = .fontColor
        navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // ナビゲーションバーの左側にボタンを設定
        guard let navigation = navigationController else { return }
        let leftBarButtonWidth = 150.0
        let navHeight = navigation.navigationBar.frame.height
        let noteView = NoteIconView(frame: CGRect(x: 0, y: 0, width: leftBarButtonWidth, height: navHeight))
        MessageListViewController.noteIconView = noteView
        noteView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moveToNoteView)))
        let leftButton = UIBarButtonItem(customView: noteView)
        leftButton.customView?.translatesAutoresizingMaskIntoConstraints = false
        leftButton.customView?.heightAnchor.constraint(equalToConstant: navHeight).isActive = true
        leftButton.customView?.widthAnchor.constraint(equalToConstant: leftBarButtonWidth).isActive = true
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        // ナビゲーションアイテムのタイトルを設定
        navigationItem.title = "メッセージ"
        // ナビゲーションバー設定
        hideNavigationBarBorderAndShowTabBarBorder()
    }
    
    private func setNavigationBarColor(_ color: UIColor) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.shadowImage = nil
        appearance.backgroundImage = nil
        appearance.backgroundEffect = nil
        appearance.backgroundColor = nil
        appearance.backgroundColor = color
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
    
    private func setUpTableView() {
        messageListTableView.tableFooterView = UIView()
        messageListTableView.delegate = self
        messageListTableView.dataSource = self
        messageListTableView.isPrefetchingEnabled = true
        messageListTableView.prefetchDataSource = self
        GlobalVar.shared.messageListTableView = messageListTableView
    }
    
    private func setUpTableViewCell() {
        messageListTableView.register(UINib(nibName: MessageListHeaderTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: MessageListHeaderTableViewCell.cellIdentifier)
        messageListTableView.register(UINib(nibName: NewMatchTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: NewMatchTableViewCell.cellIdentifier)
        messageListTableView.register(UINib(nibName: MessageListTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: MessageListTableViewCell.cellIdentifier)
    }
    
    @objc private func setUpRefreshControl() {
        GlobalVar.shared.messageListTableView.refreshControl = UIRefreshControl()
        GlobalVar.shared.messageListTableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    private func removeRefreshControl() {
        GlobalVar.shared.messageListTableView.refreshControl = nil
    }

    @objc private func handleRefreshControl() {
        DispatchQueue.main.async { 
            GlobalVar.shared.messageListTableView.reloadData()
            GlobalVar.shared.messageListTableView.refreshControl?.endRefreshing()
            self.fetchFriendList()
            Log.event(name: "reloadMessageList")
        }
    }
    
    private func setUpNotification() {
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setUpRefreshControl),
            name: NSNotification.Name(NotificationName.MessageListBack.rawValue),
            object: nil
        )
    }
    
    @objc private func foreground(_ notification: Notification) {
        print("come back foreground.")
        
        DispatchQueue.main.async {
            self.indicatorStatus = .show
            GlobalVar.shared.messageListTableView.reloadData()
            self.setUpRefreshControl()
            self.prefetcher.isPaused = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.indicatorStatus = .hide
            }
        }
    }
    
    @objc private func background(_ notification: Notification) {
        print("go to background.")
        removeRefreshControl()
        resetLatestRoomIdAndLatestUnReadCount()
        if messageListTableView != nil {
            GlobalVar.shared.messageListTableView = messageListTableView
        }
        prefetcher.isPaused = true
        indicatorStatus = .hide
    }
    
    private func moveMessageRoom(_ indexPath: IndexPath) {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        let uid = loginUser.uid
        let rooms = loginUser.rooms
        var filterRooms: [Room] = []
        
        if indexPath.section == Section.pinRoomList.rawValue {
            filterRooms = rooms.filter {
                pinnedRoomFilter(room: $0, loginUid: uid)
            }
        } else if indexPath.section == Section.roomList.rawValue {
            filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: uid)
            }
        }
        
        if let specificRoom = filterRooms[safe: indexPath.row] {
            let specificRoomID = specificRoom.document_id ?? ""
            Log.event(name: "selectMessageRoom", logEventData: ["roomID": specificRoomID])
        }
        
        let adminIdCheckStatus = loginUser.admin_checks?.admin_id_check_status
        let isAutoMatching = filterRooms[safe: indexPath.row]?.is_auto_matchig ?? false
        
        if isAutoMatching {
            if let specificRoom = filterRooms[safe: indexPath.row] {
                specificMessageRoomMove(specificRoom: specificRoom)
            }
            return
        }
        
        // 本人確認未リクエスト
        if adminIdCheckStatus == nil {
            popUpIdentificationView(nil)
        }
        // 本人確認承認済み
        else if adminIdCheckStatus == 1 {
            if let specificRoom = filterRooms[safe: indexPath.row] {
                specificMessageRoomMove(specificRoom: specificRoom)
            }
        }
        // 本人確認拒否
        else if adminIdCheckStatus == 2 {
            let alert = UIAlertController(
                title: "本人確認失敗しました",
                message: "提出していただいた写真又は生年月日に不備がありました\n再度本人確認書類を提出してください",
                preferredStyle: .alert
            )
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                self.popUpIdentificationView(nil)
            }
            alert.addAction(ok)
            
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: "本人確認中です",
                message: "現在本人確認中\n（12時間以内に承認が完了します）",
                preferredStyle: .alert
            )
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            
            present(alert, animated: true)
        }
    }
    
    @objc private func moveToNoteView() {
        let note = GlobalVar.shared.loginUser?.note
        if let note, !note.isEmpty {
            let previewVC = NotePreviewViewController(parentViewController: self)
            if let sheet = previewVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20.0
            }
            present(previewVC, animated: true)
        } else {
            let inputVC = UINavigationController(rootViewController: InputNoteViewController())
            inputVC.modalPresentationStyle = .overFullScreen
            present(inputVC, animated: true, completion: nil)
        }
    }
}

extension MessageListViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let scroll = scrollView.contentOffset.y + scrollView.frame.size.height
        
        if scrollView.contentSize.height <= scroll && beforeScrollContentOffsetY < scrollView.contentSize.height {
            // 一番下までスクロールした時に実行したい処理を記述
            print("#### MessageListViewController scrollViewDidScroll done ####")
            if isFetchPastMessageList {
                isFetchPastMessageList = false
                fetchPastMessageListInfoForFirestore()
            }
        }
        
        beforeScrollContentOffsetY = scroll
    }
}

extension MessageListViewController {
    // ルーム情報を取得
    private func fetchPastMessageListInfoForFirestore() {

        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        let loginUID = loginUser.uid
        
        guard let beforeLastDocument = GlobalVar.shared.lastRoomDocument else {
            isFetchPastMessageList = true
            return
        }
        print("fetchPastMessageListInfoForFirestore")
        let collection = db.collection("users").document(loginUID).collection("rooms")
        let query = collection.order(by: "updated_at", descending: true).limit(to: 30)
        query.start(afterDocument: beforeLastDocument).getDocuments { snapshots, error in
            if let error = error {
                print("Error fetchPastMessageList:", error)
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
            guard let lastDocument = documentChanges.last?.document else {
                return
            }
            GlobalVar.shared.lastRoomDocument = nil
            GlobalVar.shared.lastRoomDocument = lastDocument
            
            let lastDocumentID = lastDocument.documentID
            
            documentChanges.forEach { documentChange in
                self.addRoom(roomDocument: documentChange.document, lastDocumentID: lastDocumentID)
            }
            self.messageListTableView.reloadData()
            self.hideLoadingLabelAnimationAndUpdateFlug()
        }
    }
    
    private func hideLoadingLabelAnimationAndUpdateFlug() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            
        } completion: { _ in
            self.isFetchPastMessageList = true
        }
    }

    private func initLatestRoomIdAndLatestUnReadCount() {
        guard let cell = GlobalVar.shared.messageListTableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? MessageListTableViewCell else {
            return
        }
        guard let room = cell.room else {
            return
        }
        
        if GlobalVar.shared.currentLatestRoomId == nil || GlobalVar.shared.unReadCountForCurrentLatestRoom == nil {
            print("最新のRoomIDと未既読数をclassに保存")
            GlobalVar.shared.currentLatestRoomId = room.document_id
            GlobalVar.shared.unReadCountForCurrentLatestRoom = room.unreadCount
        }
    }
    
    private func resetLatestRoomIdAndLatestUnReadCount() {
        GlobalVar.shared.currentLatestRoomId = nil
        GlobalVar.shared.unReadCountForCurrentLatestRoom = nil
    }
}

// フレンド絵文字関連
extension MessageListViewController {
    
    private func getFriendEmoji(_ room: Room?) -> String? {
        guard let room = room else { return nil }
        guard let partnerUser = room.partnerUser else { return nil }
        guard let loginUser = GlobalVar.shared.loginUser else { return nil }
        let totalMessageNum = room.message_num
        let ownMessageNum = room.own_message_num
        let partnerMessageNum = totalMessageNum - ownMessageNum
        let messsageRallyNum = (ownMessageNum > partnerMessageNum ? partnerMessageNum : ownMessageNum)

//        print(
//            "totalMessageNum :", totalMessageNum,
//            "ownMessageNum :", ownMessageNum,
//            "partnerMessageNum :", partnerMessageNum,
//            "messsageRallyNum :", messsageRallyNum
//        )

        let nowDate = Date()
        let roomCreatedAt = room.created_at.dateValue()

        let sameAge = (loginUser.birth_date.calcAgeForInt() == partnerUser.birth_date.calcAgeForInt())
        let sameAddress = (loginUser.address == partnerUser.address)
        let hobbyTagMatches = loginUser.hobbies.filter({ partnerUser.hobbies.contains($0) })
        let enoughHobbyTagMatches = (hobbyTagMatches.count >= 5)

//        print(
//            "ownBirthDate :", loginUser.birth_date,
//            "ownAge :", loginUser.birth_date.calcAgeForInt(),
//            "partnerBirthDate :", partnerUser.birth_date,
//            "partnerAge :", partnerUser.birth_date.calcAgeForInt(),
//            "sameAge :", sameAge
//        )
//        print(
//            "ownAddress :", loginUser.address,
//            "partnerAddress :", partnerUser.address,
//            "sameAddress :", sameAddress
//        )
//        print(
//            "ownHobbies :", loginUser.hobbies,
//            "partnerHobbies :", partnerUser.hobbies,
//            "hobbyTagMatches :", hobbyTagMatches,
//            "enoughHobbyTagMatches :", enoughHobbyTagMatches
//        )

        let birthDateFormat = "YYYY年M月D日"
        let loginUserBirthDate = loginUser.birth_date.dateFromString(format: birthDateFormat)
        let partnerUserBirthDate = partnerUser.birth_date.dateFromString(format: birthDateFormat)

        let sssBest = "🥰💕"
        let ssBest = "❤️"
        let sBest = "💛"
        let best = "😊"
        let common = "🎾"
        let birthDay = "🎂🤝"
        var emoji = ""

        let birthDateElaspedDays = Calendar.current.dateComponents([.day], from: loginUserBirthDate, to: partnerUserBirthDate).day ?? 0

//        print(
//            "ownBirthDate :", loginUser.birth_date,
//            "partnerBirthDate :", partnerUser.birth_date,
//            "ownBirthDate (Date) :", loginUserBirthDate,
//            "partnerBirthDate (Date) :", partnerUserBirthDate,
//            "birthDateElaspedDays :", birthDateElaspedDays
//        )

        let roomElaspedDays = Calendar.current.dateComponents([.day], from: roomCreatedAt, to: nowDate).day ?? 0
        let averageMessageRallyNum = (roomElaspedDays > 0 ? (Double(messsageRallyNum) / Double(roomElaspedDays)) : 0)

//        print(
//            "partner :", partnerUser.nick_name,
//            "nowDate :", nowDate,
//            "roomCreatedAt :", roomCreatedAt,
//            "roomElaspedDays :", roomElaspedDays,
//            "messsageRallyNum :", messsageRallyNum,
//            "averageMessageRallyNum :", averageMessageRallyNum
//        )

        // SSSベストフレンド (5ラリー以上/1日, 150日以上)
        let sssBestFriend = (averageMessageRallyNum >= 5.0 && roomElaspedDays >= 150)
        // SSベストフレンド (3ラリー以上/1日, 100日以上)
        let ssBestFriend = (averageMessageRallyNum >= 3.0 && roomElaspedDays >= 100)
        // Sベストフレンド (1ラリー以上/1日, 50日以上)
        let sBestFriend = (averageMessageRallyNum >= 1.0 && roomElaspedDays >= 50)
        // ベストフレンド (0.5ラリー以上/1日, 14日以上)
        let bestFriend = (averageMessageRallyNum >= 0.5 && roomElaspedDays >= 14)
        // シークレット1 (年齢が一緒, よく行く場所が一緒, 共通の趣味タグが5個以上)
        let commonFriend = (sameAge && sameAddress && enoughHobbyTagMatches)
        // シークレット2 (相手との誕生日が一緒, 1日違いで表示)
        let birthDayFriend = (-1 <= birthDateElaspedDays && birthDateElaspedDays <= 1)

        if sssBestFriend {
            emoji += sssBest
        } else if ssBestFriend {
            emoji += ssBest
        } else if sBestFriend {
            emoji += sBest
        } else if bestFriend {
            emoji += best
        }
        if commonFriend {
            emoji += common
        }
        if birthDayFriend {
            emoji += birthDay
        }

//        print(
//            "roomElaspedDays :", roomElaspedDays,
//            "messsageRallyNum :", messsageRallyNum,
//            "averageMessageRallyNum :", averageMessageRallyNum,
//            "sameAge :", sameAge,
//            "sameAddress :", sameAddress,
//            "enoughHobbyTagMatches :", enoughHobbyTagMatches,
//            "birthDateElaspedDays :", birthDateElaspedDays
//        )
//        print(
//            "sssBestFriend :", sssBestFriend,
//            "ssBestFriend :", ssBestFriend,
//            "sBestFriend :", sBestFriend,
//            "bestFriend :", bestFriend,
//            "commonFriend :", commonFriend,
//            "birthDayFriend :", birthDayFriend
//        )

        return emoji
    }
}

// マッチ関連
extension MessageListViewController {
    
    private func matchElapsedTime(created_at: Timestamp) -> Bool {
        let date = Date()
        let span = date.timeIntervalSince(created_at.dateValue())
        let hourSpan = Int(floor(span / 60 / 60))
        
        if hourSpan < 24 {
            return true
        } else {
            return false
        }
    }
    
    private func newMatchFilter(room: Room, loginUID: String) -> Bool {
        let isLatestMessage = room.latest_message == ""
        let isMatchElapsedTime = matchElapsedTime(created_at: room.created_at) == true
        let isContainRemovedUser = room.removed_user.contains(loginUID) == false
        let isAutoMatching = room.is_auto_matchig == true
        let isForceCreateRoom = room.room_match_status == RoomMatchStatusType.force.rawValue
        let isRoomFilter = isLatestMessage && isMatchElapsedTime && isContainRemovedUser && !isAutoMatching && !isForceCreateRoom
        
        return isRoomFilter
    }
    
    private func pinnedRoomFilter(room: Room, loginUid: String) -> Bool {
        let isNewMatch = newMatchFilter(room: room, loginUID: loginUid) == true
        let isPinnedFilter = room.is_pinned == true
        
        if isNewMatch {
            return false
        }
        
        return isPinnedFilter
    }
    
    private func messageListFilter(room: Room, loginUid: String) -> Bool {
        let isNewMatch = newMatchFilter(room: room, loginUID: loginUid) == true
        let isPinned = pinnedRoomFilter(room: room, loginUid: loginUid) == true
        
        if isNewMatch || isPinned {
            return false
        }
        
        let isContainRemovedUser = room.removed_user.contains(loginUid) == false
        let isRoomFilter = isContainRemovedUser
        
        return isRoomFilter
    }
    
    private func newMatchRooms() -> [Room]? {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return nil
        }
        let uid = loginUser.uid
        let rooms = loginUser.rooms
        let newMatchRooms = rooms.filter({ newMatchFilter(room: $0, loginUID: uid) })
        
        return newMatchRooms
    }
}

// TableView関連 --- 表示設定 ---
extension MessageListViewController: UITableViewDataSource, MessageListTableViewCellDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return defaultCellheight
        }
        
        switch indexPath.section {
        case Section.header.rawValue:
            return MessageListHeaderTableViewCell.height
        case Section.newMatch.rawValue:
            if let newMatchRooms = newMatchRooms() {
                if newMatchRooms.count > 0 {
                    return NewMatchTableViewCell.height
                } else {
                    return defaultCellheight
                }
            } else {
                return defaultCellheight
            }
        case Section.pinRoomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let pinnedRooms = rooms.filter {
                pinnedRoomFilter(room:  $0, loginUid: uid)
            }
            let note = pinnedRooms[safe: indexPath.row]?.partnerUser?.note
            if let note, !note.isEmpty {
                return MessageListTableViewCell.heightWithNote
            } else {
                return MessageListTableViewCell.height
            }
        case Section.roomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: uid)
            }
            let note = filterRooms[safe: indexPath.row]?.partnerUser?.note
            if let note, !note.isEmpty {
                return MessageListTableViewCell.heightWithNote
            } else {
                return MessageListTableViewCell.height
            }
        default:
            return defaultCellheight
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return defaultCellheight
        }
        
        switch indexPath.section {
        case Section.header.rawValue:
            return MessageListHeaderTableViewCell.height
        case Section.newMatch.rawValue:
            if let newMatchRooms = newMatchRooms() {
                if newMatchRooms.count > 0 {
                    return NewMatchTableViewCell.height
                } else {
                    return defaultCellheight
                }
            } else {
                return defaultCellheight
            }
        case Section.pinRoomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let pinnedRooms = rooms.filter {
                pinnedRoomFilter(room:  $0, loginUid: uid)
            }
            let note = pinnedRooms[safe: indexPath.row]?.partnerUser?.note
            if let note, !note.isEmpty {
                return MessageListTableViewCell.heightWithNote
            } else {
                return MessageListTableViewCell.height
            }
        case Section.roomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: uid)
            }
            let note = filterRooms[safe: indexPath.row]?.partnerUser?.note
            if let note, !note.isEmpty {
                return MessageListTableViewCell.heightWithNote
            } else {
                return MessageListTableViewCell.height
            }
        default:
            return defaultCellheight
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return defaultRowsInSection
        }
        
        switch section {
        case Section.header.rawValue:
            return 1
        case Section.newMatch.rawValue:
            return 1
        case Section.pinRoomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let pinnedRooms = rooms.filter {
                pinnedRoomFilter(room:  $0, loginUid: uid)
            }
            return pinnedRooms.count
        case Section.roomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: uid)
            }
            return filterRooms.count
        default:
            return defaultRowsInSection
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.tableFooterView = UIView(frame: .zero)
        let cell = UITableViewCell()
        
        guard let loginUser = GlobalVar.shared.loginUser else {
            return cell
        }
        guard let newMatchRooms = newMatchRooms() else {
            return cell
        }
        
        if indexPath.section == Section.header.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageListHeaderTableViewCell.cellIdentifier) as! MessageListHeaderTableViewCell
            return cell
        } else if indexPath.section == Section.newMatch.rawValue {
            if newMatchRooms.count > 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: NewMatchTableViewCell.cellIdentifier, for: indexPath) as! NewMatchTableViewCell
                cell.configure(with: newMatchRooms)
                return cell
            } else {
                return cell
            }
        } else if indexPath.section == Section.pinRoomList.rawValue {
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageListTableViewCell.identifier, for: indexPath) as! MessageListTableViewCell
            cell.isHidden = false // 初回表示で何故か非表示になっているセルが存在するのでフラグ追加
            let pinnedRooms = rooms.filter {
                pinnedRoomFilter(room: $0, loginUid: uid)
            }
            if pinnedRooms[safe: indexPath.row] != nil {
                cell.room = pinnedRooms[indexPath.row]
                if let roomId = pinnedRooms[indexPath.row].document_id {
                    if roomId == cell.room?.document_id {
                        // 🥰💕etc...をここでセット
                        cell.friendEmoji = getFriendEmoji(cell.room)
                        // ⌛️をここでセット非同期のため'fetchConsectiveCount'で事前取得している
                        cell.consectiveCount = GlobalVar.shared.consectiveCountDictionary[roomId]
                    }
                }
                return cell
            }
        } else if indexPath.section == Section.roomList.rawValue {
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageListTableViewCell.identifier, for: indexPath) as! MessageListTableViewCell
            cell.delegate = self
            cell.isHidden = false // 初回表示で何故か非表示になっているセルが存在するのでフラグ追加
            let filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: uid)
            }
            if filterRooms[safe: indexPath.row] != nil {
                cell.room = filterRooms[indexPath.row]
                if let roomId = filterRooms[indexPath.row].document_id {
                    if roomId == cell.room?.document_id {
                        // 🥰💕etc...をここでセット
                        cell.friendEmoji = getFriendEmoji(cell.room)
                        // ⌛️をここでセット非同期のため'fetchConsectiveCount'で事前取得している
                        cell.consectiveCount = GlobalVar.shared.consectiveCountDictionary[roomId]
                    }
                }
                return cell
            } else {
                return cell
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case Section.header.rawValue:
            let storyboard = UIStoryboard(name: BusinessSolicitationCrackdownViewController.storyboardName, bundle: nil)
            let viewcontroller = storyboard.instantiateViewController(withIdentifier: BusinessSolicitationCrackdownViewController.storyboardId)
            navigationController?.pushViewController(viewcontroller, animated: true)
        case Section.newMatch.rawValue:
            return
        case Section.pinRoomList.rawValue:
            moveMessageRoom(indexPath)
        case Section.roomList.rawValue:
            moveMessageRoom(indexPath)
        default:
            return
        }
    }
    
    func onUserImageViewTapped(_ cell: MessageListTableViewCell, user: User) {
        profileDetailMove(user: user, className: MessageListViewController.storyboardName)
    }
}

// スワイプ関連
extension MessageListViewController {
    
    private func isRoomListCell(_ indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case Section.header.rawValue:
            return false
        case Section.newMatch.rawValue:
            return false
        case Section.pinRoomList.rawValue:
            return true
        case Section.roomList.rawValue:
            return true
        default:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !isRoomListCell(indexPath) {
            return nil
        }
        
        let delete = deleteAction(indexPath)
        let swipeAction: UISwipeActionsConfiguration?
        swipeAction = UISwipeActionsConfiguration(actions:[delete])
        swipeAction?.performsFirstActionWithFullSwipe = false
            
        return swipeAction
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !isRoomListCell(indexPath) {
            return nil
        }
        
        guard let loginUser = GlobalVar.shared.loginUser else {
            return nil
        }
        var filterRooms: [Room] = []
        
        if indexPath.section == Section.pinRoomList.rawValue {
            filterRooms = loginUser.rooms.filter{
                pinnedRoomFilter(room: $0, loginUid: loginUser.uid)
            }
        } else if indexPath.section == Section.roomList.rawValue {
            filterRooms = loginUser.rooms.filter{
                messageListFilter(room: $0, loginUid: loginUser.uid)
            }
        }
        
        if let room = filterRooms[safe: indexPath.row] {
            let pinning = pinningAction(indexPath)
            let unpinning = unpinningAction(indexPath)
            let swipeAction: UISwipeActionsConfiguration?
            
            if room.is_pinned {
                swipeAction = UISwipeActionsConfiguration(actions:[unpinning])
            } else {
                swipeAction = UISwipeActionsConfiguration(actions:[pinning])
            }
            swipeAction?.performsFirstActionWithFullSwipe = false
            
            return swipeAction
        }
        
        return nil
    }
    
    private func deleteAction(_ indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "delete") { [weak self] ctxAction, view, completionHandler in
            guard let self else { return }
            
            deleteRoom(indexPath)
            completionHandler(true)
        }
        action.image = UIImage(systemName: "trash.fill")?.withTintColor(UIColor.white , renderingMode: .alwaysTemplate)
        action.backgroundColor = .red
        
        return action
    }
    
    private func pinningAction(_ indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "pin") { [weak self] ctxAction, view, completionHandler in
            guard let self else { return }
            
            pinningRoom(indexPath)
            completionHandler(true)
        }
        action.image = UIImage(systemName: "pin.fill")?.withTintColor(UIColor.white, renderingMode: .automatic)
        action.backgroundColor = .accentColor
        
        return action
    }
    
    private func unpinningAction(_ indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: "unpin") { [weak self] ctxAction, view, completionHandler in
            guard let self else { return }
            
            unpinRoom(indexPath)
            completionHandler(true)
        }
        action.image = UIImage(systemName: "pin.slash.fill")?.withTintColor(UIColor.white, renderingMode: .alwaysTemplate)
        action.backgroundColor = .accentColor
        
        return action
    }
    
    private func deleteRoom(_ indexPath: IndexPath) {
        if !isRoomListCell(indexPath) {
            return
        }
        
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        var filterRooms: [Room] = []
        
        if indexPath.section == Section.pinRoomList.rawValue {
            filterRooms = loginUser.rooms.filter {
                pinnedRoomFilter(room: $0, loginUid: loginUser.uid)
            }
        } else if indexPath.section == Section.roomList.rawValue {
            filterRooms = loginUser.rooms.filter {
                messageListFilter(room: $0, loginUid: loginUser.uid)
            }
        }
        
        if filterRooms[safe: indexPath.row] != nil {
            let title = "本当に削除しますか？"
            let subTitle = "1度削除するとお相手からメッセージが来ない限り復元しませんが\n本当にトークルームを削除しますか？"
            
            dialog(title: title, subTitle: subTitle, confirmTitle: "OK", completion: { [weak self] confirm in
                guard let self else { return }
                
                if confirm {
                    indicatorStatus = .show
                    
                    guard let roomId = filterRooms[indexPath.row].document_id else {
                        return
                    }
                    let document = db.collection("rooms").document(roomId)
                    let updateData: [String: Any] = [
                        "removed_user": FieldValue.arrayUnion([loginUser.uid]),
                        "unread_\(loginUser.uid)": 0,
                    ]
                    
                    document.updateData(updateData) { error in
                        if let error = error {
                            print("セルの削除に失敗:", error)
                            self.alert(title: "失敗", message: "ルームの削除に失敗しました。時間をおいてもう一度お試しください。", actiontitle: "OK")
                            self.indicatorStatus = .hide
                            return
                        }
                        
                        GlobalVar.shared.loginUser?.rooms.enumerated().forEach { index, room in
                            if room.document_id == filterRooms[safe: indexPath.row]?.document_id {
                                GlobalVar.shared.loginUser?.rooms[index].removed_user.append(loginUser.uid)
                                GlobalVar.shared.loginUser?.rooms.remove(at: index)
                                GlobalVar.shared.loginUser?.room_removed_user_id_list.append(room.partnerUser?.uid ?? "")
                                
                                self.messageListTableView.beginUpdates()
                                self.messageListTableView.deleteRows(at: [indexPath], with: .fade)
                                self.messageListTableView.endUpdates()
                                self.sortRoomsForPinnedAction()
                            }
                        }
                        
                        Log.event(name: "removeMessageRoom", logEventData: ["roomID": roomId])
                        self.indicatorStatus = .hide
                    }
                }
            })
        }
    }
    
    private func pinningRoom(_ indexPath: IndexPath) {
        if !isRoomListCell(indexPath) {
            return
        }
        
        guard let loginUser = GlobalVar.shared.loginUser else { 
            return
        }
        let filterRooms = loginUser.rooms.filter {
            messageListFilter(room: $0, loginUid: loginUser.uid)
        }
        
        if let room = filterRooms[safe: indexPath.row], let roomID = room.document_id {
            indicatorStatus = .show
            
            let document = db.collection("rooms").document(roomID)
            let updateData: [String: Bool] = ["is_pinned_by_\(loginUser.uid)": true]
            
            document.updateData(updateData) { error in
                if error != nil {
                    print("セルのピン留めに失敗:", error as Any)
                    self.alert(title: "失敗", message: "ピン留めに失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                    self.indicatorStatus = .hide
                    return
                }
                
                room.is_pinned = true
                self.sortRoomsForPinnedAction()
                self.indicatorStatus = .hide
            }
        }
    }
    
    private func unpinRoom(_ indexPath: IndexPath) {
        if !isRoomListCell(indexPath) {
            return
        }
        
        guard let loginUser = GlobalVar.shared.loginUser else { 
            return
        }
        let pinnedRooms = loginUser.rooms.filter {
            pinnedRoomFilter(room: $0, loginUid: loginUser.uid)
        }
        
        if let room = pinnedRooms[safe: indexPath.row], let roomID = room.document_id {
            indicatorStatus = .show
            
            let document = db.collection("rooms").document(roomID)
            let updateData: [String: Bool] = ["is_pinned_by_\(loginUser.uid)": false]
            
            document.updateData(updateData) { error in
                if error != nil {
                    print("セルのピン留め解除に失敗:", error as Any)
                    self.alert(title: "失敗", message: "ピン留め解除に失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                    self.indicatorStatus = .hide
                    return
                }
                
                room.is_pinned = false
                self.sortRoomsForPinnedAction()
                self.indicatorStatus = .hide
            }
        }
    }
    
    private func sortRoomsForPinnedAction() {
        guard let rooms = GlobalVar.shared.loginUser?.rooms else {
            return
        }
        var pinnedRooms = rooms.filter { $0.is_pinned == true }
        var unpinnedRooms = rooms.filter { $0.is_pinned == false }

        pinnedRooms.sort { r1, r2 in
            r1.updated_at.dateValue() > r2.updated_at.dateValue()
        }
        unpinnedRooms.sort { r1, r2 in
            r1.updated_at.dateValue() > r2.updated_at.dateValue()
        }
        let sortedRooms = pinnedRooms + unpinnedRooms
        
        GlobalVar.shared.loginUser?.rooms = sortedRooms
        GlobalVar.shared.messageListTableView.reloadData()
    }
}

// TableView関連 --- prefetch ---
extension MessageListViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        let uid = loginUser.uid
        let rooms = loginUser.rooms
        let filterRooms = rooms.filter {
            if $0.is_pinned {
                pinnedRoomFilter(room: $0, loginUid: uid)
            } else {
                messageListFilter(room: $0, loginUid: uid)
            }
        }
        let urls = indexPaths.compactMap {
            getPartnerIconImgURL(filterRooms, index: $0.section)
        }
        prefetcher.startPrefetching(with: urls)
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        let uid = loginUser.uid
        let rooms = loginUser.rooms
        let filterRooms = rooms.filter {
            if $0.is_pinned {
                pinnedRoomFilter(room: $0, loginUid: uid)
            } else {
                messageListFilter(room: $0, loginUid: uid)
            }
        }
        let urls = indexPaths.compactMap {
            getPartnerIconImgURL(filterRooms, index: $0.section)
        }
        prefetcher.stopPrefetching(with: urls)
    }
    
    func getPartnerIconImgURL(_ rooms: [Room], index: Int) -> URL? {
        let partnerUser = rooms[index].partnerUser
        let profileIconImg = partnerUser?.profile_icon_img ?? ""
        let iconImgURL = URL(string: profileIconImg)
        
        return iconImgURL
    }
}

// MARK: - Context Menus -- 長押しでプレビューを表示
extension MessageListViewController {
    
    /// Returns a context menu configuration for the row at a point.
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let loginUser = GlobalVar.shared.loginUser else { return nil }
        
        let loginUID = loginUser.uid
        //本人確認していない場合は確認ページを表示
        guard let adminIDCheckStatus = loginUser.admin_checks?.admin_id_check_status else {
            popUpIdentificationView(nil)
            return nil
        }
        
        if adminIDCheckStatus == 1 {
            let rooms = loginUser.rooms
            var filterRooms: [Room] = []
            
            if indexPath.section == Section.pinRoomList.rawValue {
                filterRooms = rooms.filter {
                    pinnedRoomFilter(room: $0, loginUid: loginUID)
                }
            } else if indexPath.section == Section.roomList.rawValue {
                filterRooms = rooms.filter {
                    messageListFilter(room: $0, loginUid: loginUID)
                }
            }
            
            guard let specificRoom = filterRooms[safe: indexPath.row] else { 
                return nil
            }
            // 1. identifierの定義
            let identifier = indexPath as NSCopying
            // 2. プレビューの定義
            let previewProvider: () -> MessageRoomPreviewViewController? = { [unowned self] in
                let _ = self
                let preview = MessageRoomPreviewViewController(room: specificRoom)
                let screenSize = UIScreen.main.bounds.size
                preview.preferredContentSize = CGSize(width: screenSize.width * 0.9, height: screenSize.height * 0.7)
                return preview
            }
            
            // 3. メニューの定義
            let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
                return nil
            }
            
            return UIContextMenuConfiguration(
                identifier: identifier,
                previewProvider: previewProvider,
                actionProvider: actionProvider
            )
        } else {
            // adminIDCheckStatus != 1の場合は、nilを返してインタラクションを開始しない
            return nil
        }
    }
    
    /// Informs the delegate when a user triggers a commit by tapping the preview.
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
        guard let indexPath = configuration.identifier as? IndexPath else { return }
        guard let loginUser = GlobalVar.shared.loginUser else { return }
        
        let loginUID = loginUser.uid
        let rooms = loginUser.rooms
        var filterRooms: [Room] = []
        
        if indexPath.section == Section.pinRoomList.rawValue {
            filterRooms = rooms.filter {
                pinnedRoomFilter(room: $0, loginUid: loginUID)
            }
        } else if indexPath.section == Section.roomList.rawValue {
            filterRooms = rooms.filter {
                messageListFilter(room: $0, loginUid: loginUID)
            }
        }
        
        if let specificRoom = filterRooms[safe: indexPath.row] {
            let specificRoomID = specificRoom.document_id ?? ""
            let logEventData = [
                "roomID": specificRoomID
            ] as [String : Any]
            Log.event(name: "selectMessageRoom", logEventData: logEventData)
        }
        
        if let specificRoom = filterRooms[safe: indexPath.row] {
            specificMessageRoomMove(specificRoom: specificRoom)
            
            if indexPath.section == Section.pinRoomList.rawValue {
                GlobalVar.shared.loginUser?.rooms.filter({ pinnedRoomFilter(room: $0, loginUid: loginUID) })[indexPath.row].unreadCount = 0
                GlobalVar.shared.loginUser?.rooms.filter({ pinnedRoomFilter(room: $0, loginUid: loginUID) })[indexPath.row].unread = 0
            } else if indexPath.section == Section.roomList.rawValue {
                GlobalVar.shared.loginUser?.rooms.filter({ messageListFilter(room: $0, loginUid: loginUID) })[indexPath.row].unreadCount = 0
                GlobalVar.shared.loginUser?.rooms.filter({ messageListFilter(room: $0, loginUid: loginUID) })[indexPath.row].unread = 0
            }
            
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}

// MARK: - マッチ済みユーザの再取得
extension MessageListViewController {
    private func fetchFriendList() {
        guard let loginUser = GlobalVar.shared.loginUser, let messageRooms = GlobalVar.shared.loginUser?.rooms else { return }
        Task {
            do {
                let filterMessageRooms = messageRooms.filter({
                    let room = $0
                    let containRemovedUser = room.removed_user.firstIndex(of: loginUser.uid) == nil
                    return containRemovedUser
                })
                
                let roomPartnerUsers = filterMessageRooms.map(
                    { $0.members.filter({ $0 != loginUser.uid }).first ?? "" }).filter({ $0 != "" }
                    )
                
                try await getUsers(partnerUsers: roomPartnerUsers, rooms: filterMessageRooms)
            } catch {
                print("Fail getMessageRooms:", error)
                alert(title: "失敗", message: "情報の読み込みに失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
            }
        }
    }
    
    private func getUsers(partnerUsers: [String], rooms: [Room]) async throws {
        guard let loginUser = GlobalVar.shared.loginUser else { return }
        do {
            let perPage = partnerUsers.count
            let searchFilterBy = "uid: \(partnerUsers)"
            let searchParameters = SearchParameters(q: "*", queryBy: "", filterBy: searchFilterBy, perPage: perPage)
            let typesenseClient = GlobalVar.shared.typesenseClient
            let documents = typesenseClient.collection(name: "users").documents()
            let (searchResult, _) = try await documents.search(searchParameters, for: CardUserQuery.self)
            
            guard let hits = searchResult?.hits, hits.count != 0 else { return }
            
            let users = hits.map({ User(cardUserQuery: $0) })
            let filterUsers = users.filter { $0.uid != loginUser.uid }
            
            updatePartnerUsersData(filterUsers)
        } catch {
            throw error
        }
    }
    
    private func updatePartnerUsersData(_ users: [User]) {
        guard let myRooms = GlobalVar.shared.loginUser?.rooms else { return }
        let fetchedUserDictionary = Dictionary(uniqueKeysWithValues: zip(users.map({ $0.uid}), users))
        for room in myRooms {
            if let user = fetchedUserDictionary[room.partnerUser?.uid ?? ""] {
                room.partnerUser = user
            }
        }
        DispatchQueue.main.async {
            GlobalVar.shared.messageListTableView.reloadData()
        }
    }
}
