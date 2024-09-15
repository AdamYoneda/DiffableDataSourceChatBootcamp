
import UIKit
import Foundation
import FirebaseFirestore

struct Room {
    var members: [String]
    var latest_message_id: String
    var latest_message: String?
    var latest_sender: String?
    var send_message: String?
    var creator: String
    
    var unread: Int
    var unread_ids: [String: String]
    var message_num: Int
    let created_at: Timestamp
    var updated_at: Timestamp
    var document_id: String?
    var nicknames: [String: String]
    var is_pinned: Bool
    // DBには反映させていないが処理のためインスタンス内にデータとして持つ
    var messages: [Message]?
    var partnerUser: User?
    var unreadCount = 0
    var partnerNickname: String?
    var partnerUnreadID: String?
    
    init(data: [String:Any]) {
        let currentUID                   = GlobalVar.shared.loginUser?.uid ?? ""
        self.document_id                 = data["room_id"] as? String ?? ""
        self.members                     = data["members"] as? [String] ?? []
        self.latest_message_id           = data["latest_message_id"] as? String ?? ""
        self.latest_message              = data["latest_message"] as? String ?? ""
        self.latest_sender               = data["latest_sender"] as? String ?? ""
        self.send_message                = data["send_message_\(currentUID)"] as? String ?? ""
        self.creator                     = data["creator"] as? String ?? ""
        self.unread                      = data["unread_\(currentUID)"] as? Int ?? 0
        self.unread_ids                  = data["unread_ids"] as? [String:String] ?? [:]
        self.message_num                 = data["message_num"] as? Int ?? 0
        self.created_at                  = data["created_at"] as? Timestamp ?? Timestamp()
        let updatedAt                    = data["updated_at"] as? Timestamp ?? Timestamp()
        let ownUpdatedAt                 = data["updated_at_\(currentUID)"] as? Timestamp ?? updatedAt
        self.updated_at                  = (ownUpdatedAt.dateValue() > updatedAt.dateValue() ? ownUpdatedAt : updatedAt)
        self.nicknames                   = data["nicknames"] as? [String: String] ?? [:]
        self.is_pinned                   = data["is_pinned_by_\(currentUID)"] as? Bool ?? false
        self.partnerNickname             = generatePartnerNickname(currentUID: currentUID, members: members, nicknames: nicknames)
        self.partnerUnreadID             = getPartnerUnreadID(currentUID: currentUID, members: members, unread_ids: unread_ids)
    }
    
    init(document: QueryDocumentSnapshot) {
        let currentUID                   = GlobalVar.shared.loginUser?.uid ?? ""
        self.document_id                 = document.documentID
        let data                         = document.data()
        self.members                     = data["members"] as? [String] ?? []
        self.latest_message_id           = data["latest_message_id"] as? String ?? ""
        self.latest_message              = data["latest_message"] as? String ?? ""
        self.latest_sender               = data["latest_sender"] as? String ?? ""
        self.send_message                = data["send_message_\(currentUID)"] as? String ?? ""
        self.creator                     = data["creator"] as? String ?? ""
        self.unread                      = data["unread_\(currentUID)"] as? Int ?? 0
        self.unread_ids                  = data["unread_ids"] as? [String:String] ?? [:]
        self.message_num                 = data["message_num"] as? Int ?? 0
        self.created_at                  = data["created_at"] as? Timestamp ?? Timestamp()
        let updatedAt                    = data["updated_at"] as? Timestamp ?? Timestamp()
        let ownUpdatedAt                 = data["updated_at_\(currentUID)"] as? Timestamp ?? updatedAt
        self.updated_at                  = (ownUpdatedAt.dateValue() > updatedAt.dateValue() ? ownUpdatedAt : updatedAt)
        self.nicknames                   = data["nicknames"] as? [String: String] ?? [:]
        self.is_pinned                   = data["is_pinned_by_\(currentUID)"] as? Bool ?? false
        self.partnerNickname             = generatePartnerNickname(currentUID: currentUID, members: members, nicknames: nicknames)
        self.partnerUnreadID             = getPartnerUnreadID(currentUID: currentUID, members: members, unread_ids: unread_ids)
    }
    
    init(document: DocumentSnapshot) {
        let currentUID                   = GlobalVar.shared.loginUser?.uid ?? ""
        self.document_id                 = document.documentID
        let data                         = document.data()
        self.members                     = data?["members"] as? [String] ?? []
        self.latest_message_id           = data?["latest_message_id"] as? String ?? ""
        self.latest_message              = data?["latest_message"] as? String ?? ""
        self.latest_sender               = data?["latest_sender"] as? String ?? ""
        self.send_message                = data?["send_message_\(currentUID)"] as? String ?? ""
        self.creator                     = data?["creator"] as? String ?? ""
        self.unread                      = data?["unread_\(currentUID)"] as? Int ?? 0
        self.unread_ids                  = data?["unread_ids"] as? [String:String] ?? [:]
        self.message_num                 = data?["message_num"] as? Int ?? 0
        self.created_at                  = data?["created_at"] as? Timestamp ?? Timestamp()
        let updatedAt                    = data?["updated_at"] as? Timestamp ?? Timestamp()
        let ownUpdatedAt                 = data?["updated_at_\(currentUID)"] as? Timestamp ?? updatedAt
        self.updated_at                  = (ownUpdatedAt.dateValue() > updatedAt.dateValue() ? ownUpdatedAt : updatedAt)
        self.nicknames                   = data?["nicknames"] as? [String: String] ?? [:]
        self.is_pinned                   = data?["is_pinned_by_\(currentUID)"] as? Bool ?? false
        self.partnerNickname             = generatePartnerNickname(currentUID: currentUID, members: members, nicknames: nicknames)
        self.partnerUnreadID             = getPartnerUnreadID(currentUID: currentUID, members: members, unread_ids: unread_ids)
    }
    
    private func generatePartnerNickname(currentUID: String, members: [String], nicknames: [String:String]) -> String? {
        for member in members {
            if member != currentUID && !currentUID.isEmpty {
                return nicknames[member]
            }
        }
        return nil  // パートナーのUIDが見つからない場合
    }
    
    private func getPartnerUnreadID(currentUID: String, members: [String], unread_ids: [String:String]) -> String? {
        for member in members {
            if member != currentUID && !currentUID.isEmpty {
                return unread_ids[member]
            }
        }
        return nil  // パートナーの未読メッセージIDが見つからない場合
    }
    
    func initUnreadCount(room: Room, count: Int) -> Room {
        Room(data:[
                "room_id": room.document_id ?? "",
                "members": room.members,
                "latest_message_id": room.latest_message_id,
                "latest_message": room.latest_message ?? "",
                "latest_sender": room.latest_sender ?? "",
                "send_message_\(GlobalVar.shared.loginUser?.uid ?? "")": room.send_message ?? "",
                "creator": room.creator,
                "unread_\(GlobalVar.shared.loginUser?.uid ?? "")": count,
                "unread_ids": room.unread_ids,
                "message_num": room.message_num,
                "created_at": room.created_at,
                "updated_at": room.updated_at,
                "nicknames": room.nicknames,
                "is_pinned_by_\(GlobalVar.shared.loginUser?.uid ?? "")": room.is_pinned
             ]
        )
    }
    
    mutating func updateSendMessageText(_ text: String) {
        self.send_message = text
    }
}
