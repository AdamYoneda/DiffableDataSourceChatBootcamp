
import Foundation
import FirebaseFirestore

struct User {
    
    var uid: String
    var nick_name: String
    var email: String
    var profile_icon_img: String
    var note: String
    let created_at: Timestamp
    var note_updated_at: Timestamp? = nil // デフォルトはnil
    
    /// DBには反映させていないが処理のためインスタンス内にデータとして持つ
    var rooms = [Room]()
    
    init(document: QueryDocumentSnapshot) {
        let data                       = document.data()
        uid                            = document.documentID
        nick_name                      = data["nick_name"] as? String ?? ""
        email                          = data["email"] as? String ?? ""
        profile_icon_img               = data["profile_icon_img"] as? String ?? ""
        note                           = data["note"] as? String ?? ""
        created_at                     = data["created_at"] as? Timestamp ?? Timestamp()
        note_updated_at                = data["note_updated_at"] as? Timestamp
    }
    
    init(document: DocumentSnapshot) {
        let data                       = document.data()
        uid                            = document.documentID
        nick_name                      = data?["nick_name"] as? String ?? ""
        email                          = data?["email"] as? String ?? ""
        profile_icon_img               = data?["profile_icon_img"] as? String ?? ""
        note                           = data?["note"] as? String ?? ""
        created_at                     = data?["created_at"] as? Timestamp ?? Timestamp()
        note_updated_at                = data?["note_updated_at"] as? Timestamp
    }
    
    mutating func initRoomUnreadCount(index: Int, room: Room) {
        self.rooms[index] = room
    }
}
