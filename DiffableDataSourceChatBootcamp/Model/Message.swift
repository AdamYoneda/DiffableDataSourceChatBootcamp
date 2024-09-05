//
//  Message.swift
//  Tatibanashi
//
//  Created by Apple on 2022/02/21.
//

import Foundation
import FirebaseFirestore

final class Message: Identifiable {
    var id: UUID
    var room_id: String
    var text: String
    var photos = [String]()
    var sticker: UIImage?
    var stickerIdentifier: String
    var read: Bool
    var creator: String
    var members = [String]()
    var type: CustomMessageType
    var created_at: Timestamp
    var updated_at: Timestamp
    var is_deleted: Bool
    var is_unread: Bool = false
    var reactionEmoji: String
    var reply_message_id: String?
    var reply_message_text: String?
    var reply_message_creator: String?
    var reply_message_image_urls: [String]?
    var reply_message_type: CustomMessageType?
    var document_id: String?
    
    init(room_id: String, text: String, photos: [String], sticker: UIImage?, stickerIdentifier: String, read: Bool, creator: String, members: [String],
         type: CustomMessageType, created_at: Timestamp, updated_at: Timestamp, is_deleted: Bool,
         reactionEmoji: String, reply_message_id: String?, reply_message_text: String?, reply_message_creator: String?, reply_message_image_urls: [String]?, reply_message_type: CustomMessageType?, document_id: String?) {
        guard let document_id else { fatalError("Message.document_idが存在しない") }
        self.document_id              = document_id
        self.id                       = UUID(uuidString: document_id) ?? UUID()
        self.room_id                  = room_id
        self.text                     = text
        self.photos                   = photos
        self.sticker                  = sticker
        self.stickerIdentifier        = stickerIdentifier
        self.read                     = read
        self.creator                  = creator
        self.members                  = members
        self.type                     = type
        self.created_at               = created_at
        self.updated_at               = updated_at
        self.is_deleted               = is_deleted
        self.reactionEmoji            = reactionEmoji
        self.reply_message_id         = reply_message_id
        self.reply_message_text       = reply_message_text
        self.reply_message_creator    = reply_message_creator
        self.reply_message_image_urls = reply_message_image_urls
        self.reply_message_type       = reply_message_type
    }
    
    init(document: QueryDocumentSnapshot) {
        document_id              = document.documentID
        id                       = UUID(uuidString: document.documentID) ?? UUID()
        let data                 = document.data()
        let typeInt              = data["type"] as? Int ?? 0
        type                     = CustomMessageType(rawValue: typeInt) ?? .text
        room_id                  = data["room_id"] as? String ?? ""
        text                     = data["text"] as? String ?? ""
        photos                   = data["photos"] as? [String] ?? [String]()
        stickerIdentifier        = data["sticker_identifier"] as? String ?? ""
        read                     = data["read"] as? Bool ?? false
        creator                  = data["creator"] as? String ?? ""
        members                  = data["members"] as? [String] ?? [String]()
        created_at               = data["created_at"] as? Timestamp ?? Timestamp()
        updated_at               = data["updated_at"] as? Timestamp ?? Timestamp()
        is_deleted               = data["is_deleted"] as? Bool ?? false
        reactionEmoji            = data["reaction"] as? String ?? ""
        reply_message_id         = data["reply_message_id"] as? String ?? ""
        reply_message_text       = data["reply_message_text"] as? String ?? ""
        reply_message_creator    = data["reply_message_creator"] as? String ?? ""
        reply_message_image_urls = data["reply_message_image_urls"] as? [String] ?? [String]()
        let replyTypeInt         = data["reply_message_type"] as? Int ?? 0
        reply_message_type       = CustomMessageType(rawValue: replyTypeInt) ?? .text
    }
    
    init(document: DocumentSnapshot) {
        document_id              = document.documentID
        id                       = UUID(uuidString: document.documentID) ?? UUID()
        let data                 = document.data()
        let typeInt              = data?["type"] as? Int ?? 0
        type                     = CustomMessageType(rawValue: typeInt) ?? .text
        room_id                  = data?["room_id"] as? String ?? ""
        text                     = data?["text"] as? String ?? ""
        photos                   = data?["photos"] as? [String] ?? [String]()
        stickerIdentifier        = data?["sticker_identifier"] as? String ?? ""
        read                     = data?["read"] as? Bool ?? false
        creator                  = data?["creator"] as? String ?? ""
        members                  = data?["members"] as? [String] ?? [String]()
        created_at               = data?["created_at"] as? Timestamp ?? Timestamp()
        updated_at               = data?["updated_at"] as? Timestamp ?? Timestamp()
        is_deleted               = data?["is_deleted"] as? Bool ?? false
        reactionEmoji            = data?["reaction"] as? String ?? ""
        reply_message_id         = data?["reply_message_id"] as? String ?? ""
        reply_message_text       = data?["reply_message_text"] as? String ?? ""
        reply_message_creator    = data?["reply_message_creator"] as? String ?? ""
        reply_message_image_urls = data?["reply_message_image_urls"] as? [String] ?? [String]()
        let replyTypeInt         = data?["reply_message_type"] as? Int ?? 0
        reply_message_type       = CustomMessageType(rawValue: replyTypeInt) ?? .text
    }
    
    static func generateUnreadMessage(timestamp: Timestamp) -> Message {
        let message = Message(
            room_id: "",
            text: "",
            photos: [],
            sticker: nil,
            stickerIdentifier: "",
            read: false,
            creator: "",
            members: [],
            type: .talk,
            created_at: timestamp,
            updated_at: timestamp,
            is_deleted: false,
            reactionEmoji: "",
            reply_message_id: nil,
            reply_message_text: nil,
            reply_message_creator: nil,
            reply_message_image_urls: nil,
            reply_message_type: nil,
            document_id: UUID().uuidString
        )
        message.is_unread = true
        
        return message
    }
}
