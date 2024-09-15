

import UIKit
import FirebaseFirestore

final class MessageListViewController: UIViewController {

    @IBOutlet weak var messageListTableView: UITableView!
    
    private let db = Firestore.firestore()
    
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
    
    private var lastRoomDocument: QueryDocumentSnapshot?
    
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
        case pinRoomList = 0
        case roomList = 1
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
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.indicatorStatus = .hide
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeRefreshControl()
        if messageListTableView != nil {
            GlobalVar.shared.messageListTableView = messageListTableView
        }
        indicatorStatus = .hide
    }
    
    private func setUp() {
        indicatorStatus = .show
        setUpNavigationBar()
        setUpTableView()
        setUpTableViewCell()
        setUpNotification()
    }
    
    private func setUpNavigationBar() {
        // ナビゲーションバーを表示する
        navigationController?.setNavigationBarHidden(false, animated: true)
        // ナビゲーションの戻るボタンを消す
        navigationItem.setHidesBackButton(true, animated: true)
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
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()
        navigationBarAppearance.backgroundColor = .white
        navigationController?.navigationBar.standardAppearance = navigationBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearance
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
        GlobalVar.shared.messageListTableView = messageListTableView
    }
    
    private func setUpTableViewCell() {
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
            name: NSNotification.Name("MessageListBack"),
            object: nil
        )
    }
    
    @objc private func foreground(_ notification: Notification) {
        print("come back foreground.")
        
        DispatchQueue.main.async {
            self.indicatorStatus = .show
            GlobalVar.shared.messageListTableView.reloadData()
            self.setUpRefreshControl()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.indicatorStatus = .hide
            }
        }
    }
    
    @objc private func background(_ notification: Notification) {
        print("go to background.")
        removeRefreshControl()
        if messageListTableView != nil {
            GlobalVar.shared.messageListTableView = messageListTableView
        }
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
            if specificRoom.partnerUser == nil {
                return
            }
            
            Task {
                let storyBoard = UIStoryboard.init(name: "MessageRoomView", bundle: nil)
                let messageRoomVC = storyBoard.instantiateViewController(withIdentifier: "MessageRoomView") as! MessageRoomView
                messageRoomVC.room = specificRoom
                navigationController?.pushViewController(messageRoomVC, animated: true)
            }
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
    
    private func pinnedRoomFilter(room: Room, loginUid: String) -> Bool {
        return room.is_pinned == true
    }
    
    private func messageListFilter(room: Room, loginUid: String) -> Bool {
        if pinnedRoomFilter(room: room, loginUid: loginUid) {
            return false
        } else {
            return true
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
        
        guard let beforeLastDocument = lastRoomDocument else {
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
            self.lastRoomDocument = nil
            self.lastRoomDocument = lastDocument
            
            let lastDocumentID = lastDocument.documentID
            
            documentChanges.forEach { documentChange in
                self.addRoom(roomDocument: documentChange.document, lastDocumentID: lastDocumentID)
            }
            self.messageListTableView.reloadData()
            self.hideLoadingLabelAnimationAndUpdateFlug()
        }
    }
    
    private func addRoom(roomDocument: QueryDocumentSnapshot, lastDocumentID: String) {
        guard let loginUser = GlobalVar.shared.loginUser else { return }
        let uid = loginUser.uid
        let rooms = loginUser.rooms
        var room = Room(document: roomDocument)
        guard let roomID = room.document_id else { return }
        // ルームやりとりユーザが存在しない場合、これ以降の処理をさせない
        guard let partnerUID = room.members.filter({ $0 != uid }).first else { return }
        // ルームが既に追加されていた場合、これ以降の処理をさせない
        if rooms.firstIndex(where: { $0.document_id == roomID }) != nil { return }
        
        Task {
            // メッセージ未読数を初期化
            room = room.initUnreadCount(room: room, count: room.unread)
            // メッセージルームの追加
            GlobalVar.shared.loginUser?.rooms.append(room)
            // 自分以外のルーム内のユーザー情報を取得
            room.partnerUser = try await fetchUserInfo(uid: partnerUID)
            // ルームの重複を取得
            if let roomIndex = GlobalVar.shared.loginUser?.rooms.firstIndex(where: { $0.document_id == roomID }), GlobalVar.shared.loginUser?.rooms[safe: roomIndex] != nil {
                GlobalVar.shared.loginUser?.rooms[roomIndex].partnerUser = room.partnerUser
                GlobalVar.shared.loginUser?.rooms[roomIndex].is_pinned = room.is_pinned
            }
        }
    }
    
    private func fetchUserInfo(uid: String) async throws -> User {
        let db = Firestore.firestore()
        let userDocument = try await db.collection("users").document(uid).getDocument()
        let user = User(document: userDocument)
        return user
    }
    
    private func hideLoadingLabelAnimationAndUpdateFlug() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn) {
            
        } completion: { _ in
            self.isFetchPastMessageList = true
        }
    }
}

// TableView関連 --- 表示設定 ---
extension MessageListViewController: UITableViewDelegate, UITableViewDataSource, MessageListTableViewCellDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return defaultCellheight
        }
        
        switch indexPath.section {
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
        
        switch indexPath.section {
        case Section.pinRoomList.rawValue:
            let uid = loginUser.uid
            let rooms = loginUser.rooms
            let cell = tableView.dequeueReusableCell(withIdentifier: MessageListTableViewCell.identifier, for: indexPath) as! MessageListTableViewCell
            cell.isHidden = false // 初回表示で何故か非表示になっているセルが存在するのでフラグ追加
            let pinnedRooms = rooms.filter {
                pinnedRoomFilter(room: $0, loginUid: uid)
            }
            if pinnedRooms[safe: indexPath.row] != nil {
                cell.room = pinnedRooms[indexPath.row]
                
                return cell
            }
        case Section.roomList.rawValue:
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
                
                return cell
            } else {
                return cell
            }
        default:
            fatalError("MessageListViewController: \(#function)")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case Section.pinRoomList.rawValue:
            moveMessageRoom(indexPath)
        case Section.roomList.rawValue:
            moveMessageRoom(indexPath)
        default:
            return
        }
    }
    
    func onUserImageViewTapped(_ cell: MessageListTableViewCell, user: User) {
        print(#function)
    }
}

// スワイプ関連
extension MessageListViewController {
    
    private func isRoomListCell(_ indexPath: IndexPath) -> Bool {
        switch indexPath.section {
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
            
            dialog(title: title, subTitle: subTitle, confirmTitle: "OK", completion: { confirm in
                
                if confirm {
                    print(#function)
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
        
        if var room = filterRooms[safe: indexPath.row], let roomID = room.document_id {
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
        
        if var room = pinnedRooms[safe: indexPath.row], let roomID = room.document_id {
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


// MARK: - Context Menus -- 長押しでプレビューを表示
extension MessageListViewController {
    
    /// Returns a context menu configuration for the row at a point.
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let loginUser = GlobalVar.shared.loginUser else { return nil }
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
            specificMessageRoomMove(specificRoom: specificRoom)
            
            if indexPath.section == Section.pinRoomList.rawValue {
                if let room = GlobalVar.shared.loginUser?.rooms.filter({ pinnedRoomFilter(room: $0, loginUid: loginUID) })[indexPath.row],
                   let index = GlobalVar.shared.loginUser?.rooms.firstIndex(where: { $0.document_id == room.document_id }){
                    GlobalVar.shared.loginUser?.initRoomUnreadCount(index: index, room: room)
                }
            } else if indexPath.section == Section.roomList.rawValue {
                if let room = GlobalVar.shared.loginUser?.rooms.filter({ pinnedRoomFilter(room: $0, loginUid: loginUID) })[indexPath.row],
                   let index = GlobalVar.shared.loginUser?.rooms.firstIndex(where: { $0.document_id == room.document_id }){
                    GlobalVar.shared.loginUser?.initRoomUnreadCount(index: index, room: room)
                }
                
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }
    
    private func specificMessageRoomMove(specificRoom: Room) {
        if specificRoom.partnerUser == nil {
            return
        }
        
        Task {
            let storyBoard = UIStoryboard.init(name: "MessageRoomView", bundle: nil)
            let messageRoomVC = storyBoard.instantiateViewController(withIdentifier: "MessageRoomView") as! MessageRoomView
            messageRoomVC.room = specificRoom
            navigationController?.pushViewController(messageRoomVC, animated: true)
        }
    }
}
