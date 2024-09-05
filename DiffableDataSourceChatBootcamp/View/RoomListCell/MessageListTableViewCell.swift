//
//  MessageListTableViewCell.swift
//  Tauch
//
//  Created by sasaki.ken on 2023/09/29.
//

import UIKit

protocol MessageListTableViewCellDelegate: AnyObject {
    func onUserImageViewTapped(_ cell: MessageListTableViewCell, user: User)
}

final class MessageListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var pertnerNameLabel: UILabel!
    @IBOutlet weak var datelabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var friendEmojiIcon: UILabel!
    @IBOutlet weak var limitIcon: UILabel!   
    @IBOutlet weak var unreadContainerView: UIView!
    @IBOutlet weak var unreadView: UIImageView!
    @IBOutlet weak var unreadLabel: UILabel!
    @IBOutlet weak var pinImageView: UIImageView!
    @IBOutlet weak var noteView: UIView!
    // Constraints
    @IBOutlet weak var userImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var userImageViewTopConstraintWithNote: NSLayoutConstraint!
    @IBOutlet weak var partnerNameLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var partnerNameLabelTopConstraintWithNote: NSLayoutConstraint!
    @IBOutlet weak var dateLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabelTopConstraintWithNote: NSLayoutConstraint!
    
    static let nibName = "MessageListTableViewCell"
    static let cellIdentifier = "MessageListTableViewCell"
    static let height = 80.0
    static let heightWithNote = 95.0
    
    weak var delegate: MessageListTableViewCellDelegate?
    
    var room: Room? {
        didSet {
            if let room = room {
                setUserImageView(room)
                setPertnerNameLabel(room)
                setDateLabel(room)
                setMessageLabel(room)
                setUnreadView(room)
                setUpPinImageView(room)
                setNote(room)
                isHidden = false
            }
        }
    }
    
    var consectiveCount: Int? {
        didSet {
            if let room = room, let count = consectiveCount {
                limitIconEnabled(room, consectiveCount: count)
            }
        }
    }
    
    var friendEmoji: String? {
        didSet {
            if let emoji = friendEmoji {
                setFriendEmoji(emoji)
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setUpTapGesture()
    }
    
    private func setUserImageView(_ room: Room) {
        if let image = room.partnerUser?.profile_icon_img {
            userImageView.setImage(withURLString: image)
        }
    }
    
    private func setPertnerNameLabel(_ room: Room) {
        if let nickname = room.partnerNickname {
            pertnerNameLabel.text = nickname
        } else if let name = room.partnerUser?.nick_name {
            pertnerNameLabel.text = name
        } else {
            pertnerNameLabel.text = "..."
        }
    }
    
    private func setDateLabel(_ room: Room) {
        datelabel.text = ElapsedTime.format(from: room.updated_at.dateValue())
    }
    
    private func setMessageLabel(_ room: Room) {
        let latestMessage = room.latest_message
        let isRoomOpend = room.is_room_opened
        guard let uid = GlobalVar.shared.loginUser?.uid else {
            return
        }
        let isTalkGuide = room.talk_guide_users.contains(uid) == true
        let isTalkGuideUnread = isTalkGuide && talkGuideStatus(room: room)
        let isAutoMatching = room.is_auto_matchig
        let isForceCreateRoom = room.room_match_status == RoomMatchStatusType.force.rawValue
        let isCreater = room.creator == GlobalVar.shared.loginUser?.uid
        
        messageLabel.text = room.latest_message
        messageLabel.textColor = .darkGray
        
        // 特定の条件でテキストを上書き
        if latestMessage == "" && isAutoMatching {
            messageLabel.text = "Touchからおすすめのマッチングがありました！"
        } else if latestMessage == "" && isRoomOpend == false {
            messageLabel.text = "マッチングが成立しました！"
        } else if latestMessage == "" && isRoomOpend == true {
            messageLabel.text = "トークしてみよう！"
        } else if isTalkGuide {
            messageLabel.text = "Touchからあなたへのガイドが届きました。"
        }
        
        // マッチ前強制生成ルームはテキストを上書き
        if isForceCreateRoom && isCreater {
            messageLabel.text = "いいね！の承認を待っています。"
        } else if isForceCreateRoom && !isCreater {
            messageLabel.text = "友達じゃないユーザーのリクエストです。"
        }
        
        // 上書きしたテキストに対して配色を設定
        if messageLabel.text == "Touchからおすすめのマッチングがありました！"  {
            messageLabel.textColor = .messageHightLightColor
        } else if messageLabel.text == "マッチングが成立しました！" {
            messageLabel.textColor = .messageHightLightColor
        } else if messageLabel.text == "トークしてみよう！" {
            messageLabel.textColor = .darkGray
        } else if messageLabel.text == "Touchからあなたへのガイドが届きました。" {
            if isTalkGuideUnread {
                messageLabel.textColor = .messageHightLightColor
            } else {
                messageLabel.textColor = .darkGray
            }
        }
    }
    
    private func setUnreadView(_ room: Room) {
        if room.unreadCount > 0 {
            unreadContainerView.isHidden = false
            unreadView.isHidden = false
            unreadView.image = UIImage(systemName: "circle.fill")
            unreadView.tintColor = UIColor(named: "AccentColor")
            unreadLabel.text = String(room.unreadCount)
            // 3桁の場合カウントがおさまらないので分岐
            if let text = unreadLabel.text {
                if text.count >= 3 {
                    unreadLabel.font = UIFont.boldSystemFont(ofSize: 9.0)
                } else {
                    unreadLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
                }
            }
        } else if room.latest_sender == GlobalVar.shared.loginUser?.uid {
            unreadContainerView.isHidden = false
            unreadView.isHidden = false
            unreadView.image = UIImage(systemName: "checkmark.circle.fill")
            unreadView.tintColor = .lightGray
            unreadLabel.text = ""
        } else {
            unreadContainerView.isHidden = true
            unreadView.isHidden = true
            unreadLabel.text = ""
        }
    }
    
    private func setUpPinImageView(_ room: Room) {
        pinImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 4)
        
        if room.is_pinned {
            pinImageView.isHidden = false
        } else {
            pinImageView.isHidden = true
        }
    }
    
    private func setNote(_ room: Room) {
        let note = room.partnerUser?.note
        if let note, !note.isEmpty {
            noteView.isHidden = false
            noteView.removeAllSubviews()
            let bubbleTextView = NoteBubbleView(text: note)
            bubbleTextView.setBubbleColor(isNewNote: isNewNote(room: room))
            bubbleTextView.translatesAutoresizingMaskIntoConstraints = false
            noteView.addSubview(bubbleTextView)
            bubbleTextView.topAnchor.constraint(equalTo: noteView.topAnchor).isActive = true
            bubbleTextView.bottomAnchor.constraint(equalTo: noteView.bottomAnchor).isActive = true
            bubbleTextView.leadingAnchor.constraint(equalTo: noteView.leadingAnchor).isActive = true
            bubbleTextView.trailingAnchor.constraint(equalTo: noteView.trailingAnchor).isActive = true
            userImageViewTopConstraint.isActive = false
            userImageViewTopConstraintWithNote.isActive = true
            partnerNameLabelTopConstraint.isActive = false
            partnerNameLabelTopConstraintWithNote.isActive = true
            dateLabelTopConstraint.isActive = false
            dateLabelTopConstraintWithNote.isActive = true
            layoutIfNeeded()
        } else {
            noteView.isHidden = true
            userImageViewTopConstraint.isActive = true
            userImageViewTopConstraintWithNote.isActive = false
            partnerNameLabelTopConstraint.isActive = true
            partnerNameLabelTopConstraintWithNote.isActive = false
            dateLabelTopConstraint.isActive = true
            dateLabelTopConstraintWithNote.isActive = false
            layoutIfNeeded()
        }
    }
    
    /// 24時間以内か判定。note_updated_at == nilの場合はfalseを返す。
    private func isNewNote(room: Room) -> Bool {
        if let note_updated_at = room.partnerUser?.note_updated_at {
            let date = Date()
            let span = date.timeIntervalSince(note_updated_at.dateValue())
            let hourSpan = Int(floor(span / 60 / 60))
            
            if hourSpan < 24 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

// フレンド絵文字
extension MessageListTableViewCell {
    
    // ⌛️は連続記録5回以上かつ40~48hやりとりがない場合に表示
    private func limitIconEnabled(_ room: Room, consectiveCount: Int)  {
        let lastUpdatedEpochTime = Int(room.updated_at.seconds)
        let currentEpochTime = Int(Date().timeIntervalSince1970)
        let diffEposhTime = currentEpochTime - lastUpdatedEpochTime
        let minPeriodEpochTime = DateConst.hourInSeconds * 40
        let maxPeriodEpochTime = DateConst.hourInSeconds * 48
        
        limitIcon.isHidden = true
        
        if consectiveCount >= 5 {
            if diffEposhTime >= minPeriodEpochTime && diffEposhTime <= maxPeriodEpochTime {
                limitIcon.isHidden = false
            }
        }
    }
    
    private func setFriendEmoji(_ emoji: String) {
        guard let loginUser = GlobalVar.shared.loginUser else {
            return
        }
        
        if loginUser.is_friend_emoji {
            friendEmojiIcon.isHidden = false
            friendEmojiIcon.text = emoji
        } else {
            friendEmojiIcon.text = ""
        }
    }
}

// アイコンタップ
extension MessageListTableViewCell {
    
    private func setUpTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onUserImageViewTapped(_:)))
        userImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func onUserImageViewTapped(_ tapGesture: UITapGestureRecognizer) {
        if let partnerUser = room?.partnerUser {
            delegate?.onUserImageViewTapped(self, user: partnerUser)
        }
    }
}
