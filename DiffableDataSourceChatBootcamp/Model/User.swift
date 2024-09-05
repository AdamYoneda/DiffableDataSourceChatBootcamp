//
//  User.swift
//  Tatibanashi
//
//  Created by Apple on 2022/02/13.
//

import Foundation
import FirebaseFirestore
import Typesense

final class User {
    
    var uid: String
    var phone_number: String
    var nick_name: String
    var type: String
    var holiday: String
    var business: String
    var income: Int
    var email: String
    var notification_email: String
    var gender: Int
    var violation_count: Int
    var birth_date: String
    var age: Int
    var profile_icon_img: String
    var thumbnail: String
    var small_thumbnail: String
    var profile_icon_sub_imgs: [String]
    var sub_thumbnails: [String]
    var profile_header_image: String
    var profile_status: String
    var note: String
    var address: String
    var address2: String
    var hobbies = [String]()
    var peerId: String
    var fcmToken: String
    var deviceToken: String
    var is_approached_notification: Bool
    var is_matching_notification: Bool
    var is_message_notification: Bool
    var is_room_phone_notification: Bool
    var is_visitor_notification: Bool
    var is_board_reaction_notification: Bool
    var is_with_image_notification: Bool
    var is_approached_mail: Bool
    var is_matching_mail: Bool
    var is_message_mail: Bool
    var is_visitor_mail: Bool
    var is_board_reaction_mail: Bool
    var is_vibration_notification: Bool
    var is_identification_approval: Bool
    var is_deleted: Bool
    var is_activated: Bool
    var is_logined: Bool
    var is_init_reviewed: Bool
    var is_reviewed: Bool
    var is_rested: Bool
    var is_withdrawal: Bool
    var is_tutorial: Bool
    var tutorial_num: Int
    var is_talkguide: Bool
    var is_auto_message: Bool
    var is_display_ranking_talkguide: Bool = false
    var is_friend_emoji: Bool
    var is_already_auto_matched: Bool
    var is_solicitation_agreement: Bool
    var approaches = [String]()
    var approacheds = [String]()
    var reply_approacheds = [String]()
    var logouted_at: Timestamp
    let created_at: Timestamp
    let updated_at: Timestamp
    var note_updated_at: Timestamp? = nil // デフォルトはnil
    var min_age_filter: Int
    var max_age_filter: Int
    var address_filter = [String]()
    var hobby_filter = [String]()
    var admin_checks: AdminCheck?
    /// DBには反映させていないが処理のためインスタンス内にデータとして持つ
    var profileHeaderImageViewForPreview: UIImageView?
    var profileIconImageViewForPreview: UIImageView?
    var profileSubImagesForPreview: [UIImage?] = []
    var cachefirstSubImageView = UIImageView()
    var cacheSecondSubImageView = UIImageView()
    var cacheThirdSubImageView = UIImageView()
    var cacheFourSubImageView = UIImageView()
    var cacheFiveSubImageView = UIImageView()
    var cacheSixSubImageView = UIImageView()
    var cardUsers = [User]()
    var blocks = [String]()
    var violations = [String]()
    var stops = [String]()
    var approached = [Approach]()
    var rooms = [Room]()
    var visitors = [Visitor]()
    var visitorUnreadList = [String]()
    var invitations = [Invitation]()
    var invitationeds = [Invitation]()
    var deleteUsers = [String]()
    var deactivateUsers = [String]()
    var room_removed_user_id_list: [String] = []
    var post_photos: [String] = []
    // 相手ユーザとの距離をモデルで保持
    var distance: Int?
    
    init(document: QueryDocumentSnapshot) {
        let data                       = document.data()
        uid                            = document.documentID
        phone_number                   = data["phone_number"] as? String ?? ""
        nick_name                      = data["nick_name"] as? String ?? ""
        type                           = data["type"] as? String ?? "未設定"
        holiday                        = data["holiday"] as? String ?? "未設定"
        business                       = data["business"] as? String ?? "未設定"
        income                         = data["income"] as? Int ?? 0
        email                          = data["email"] as? String ?? ""
        notification_email             = data["notification_email"] as? String ?? ""
        gender                         = data["gender"] as? Int ?? 0
        violation_count                = data["violation_count"] as? Int ?? 0
        birth_date                     = data["birth_date"] as? String ?? ""
        age                            = data["age"] as? Int ?? 0
        profile_icon_img               = data["profile_icon_img"] as? String ?? ""
        thumbnail                      = data["thumbnail"] as? String ?? ""
        small_thumbnail                = data["small_thumbnail"] as? String ?? ""
        profile_icon_sub_imgs          = data["profile_icon_sub_imgs"] as? [String] ?? []
        sub_thumbnails                 = data["sub_thumbnails"] as? [String] ?? []
        profile_header_image           = data["profile_header_image"] as? String ?? ""
        profile_status                 = data["profile_status"] as? String ?? ""
        note                           = data["note"] as? String ?? ""
        address                        = data["address"] as? String ?? ""
        address2                       = data["address2"] as? String ?? ""
        hobbies                        = data["hobbies"] as? [String] ?? [String]()
        peerId                         = data["peerId"] as? String ?? ""
        fcmToken                       = data["fcmToken"] as? String ?? ""
        deviceToken                    = data["deviceToken"] as? String ?? ""
        is_approached_notification     = data["is_approached_notification"] as? Bool ?? true
        is_matching_notification       = data["is_matching_notification"] as? Bool ?? true
        is_message_notification        = data["is_message_notification"] as? Bool ?? true
        is_room_phone_notification     = data["is_room_phone_notification"] as? Bool ?? true
        is_visitor_notification        = data["is_visitor_notification"] as? Bool ?? true
        is_board_reaction_notification = data["is_board_reaction_notification"] as? Bool ?? true
        is_with_image_notification     = data["is_with_image_notification"] as? Bool ?? true
        is_approached_mail             = data["is_approached_mail"] as? Bool ?? true
        is_matching_mail               = data["is_matching_mail"] as? Bool ?? true
        is_message_mail                = data["is_message_mail"] as? Bool ?? true
        is_visitor_mail                = data["is_visitor_mail"] as? Bool ?? true
        is_board_reaction_mail         = data["is_board_reaction_mail"] as? Bool ?? true
        is_identification_approval     = data["is_identification_approval"] as? Bool ?? false
        is_vibration_notification      = data["is_vibration_notification"] as? Bool ?? true
        is_deleted                     = data["is_deleted"] as? Bool ?? false
        is_activated                   = data["is_activated"] as? Bool ?? true
        is_logined                     = data["is_logined"] as? Bool ?? false
        is_init_reviewed               = data["is_init_reviewed"] as? Bool ?? false
        is_reviewed                    = data["is_reviewed"] as? Bool ?? false
        is_rested                      = data["is_rested"] as? Bool ?? false
        is_withdrawal                  = data["is_withdrawal"] as? Bool ?? false
        is_tutorial                    = data["is_tutorial"] as? Bool ?? false
        tutorial_num                   = data["tutorial_num"] as? Int ?? 0
        is_talkguide                   = data["is_talkguide"] as? Bool ?? true
        is_auto_message                = data["is_auto_message"] as? Bool ?? true
        is_display_ranking_talkguide   = data["is_display_ranking_talkguide"] as? Bool ?? false
        is_friend_emoji                = data["is_friend_emoji"] as? Bool ?? true
        is_already_auto_matched        = data["is_already_auto_matched"] as? Bool ?? false
        is_solicitation_agreement      = data["is_solicitation_agreement"] as? Bool ?? false
        approaches                     = data["approaches"] as? [String] ?? [String]()
        approacheds                    = data["approached"] as? [String] ?? [String]()
        reply_approacheds              = data["reply_approacheds"] as? [String] ?? [String]()
        blocks                         = data["blocks"] as? [String] ?? [String]()
        violations                     = data["violations"] as? [String] ?? [String]()
        stops                          = data["stops"] as? [String] ?? [String]()
        logouted_at                    = data["logouted_at"] as? Timestamp ?? Timestamp()
        created_at                     = data["created_at"] as? Timestamp ?? Timestamp()
        updated_at                     = data["updated_at"] as? Timestamp ?? Timestamp()
        note_updated_at                = data["note_updated_at"] as? Timestamp
        min_age_filter                 = data["min_age_filter"] as? Int ?? 12
        max_age_filter                 = data["max_age_filter"] as? Int ?? 120
        address_filter                 = data["address_filter"] as? [String] ?? [String]()
        hobby_filter                   = data["hobby_filter"] as? [String] ?? [String]()
    }
    
    init(document: DocumentSnapshot) {
        let data                       = document.data()
        uid                            = document.documentID
        phone_number                   = data?["phone_number"] as? String ?? ""
        nick_name                      = data?["nick_name"] as? String ?? ""
        type                           = data?["type"] as? String ?? "気軽に誘ってください"
        holiday                        = data?["holiday"] as? String ?? "土日休み"
        business                       = data?["business"] as? String ?? "未設定"
        income                         = data?["income"] as? Int ?? 0
        email                          = data?["email"] as? String ?? ""
        notification_email             = data?["notification_email"] as? String ?? ""
        gender                         = data?["gender"] as? Int ?? 0
        violation_count                = data?["violation_count"] as? Int ?? 0
        birth_date                     = data?["birth_date"] as? String ?? ""
        age                            = data?["age"] as? Int ?? 0
        profile_icon_img               = data?["profile_icon_img"] as? String ?? ""
        thumbnail                      = data?["thumbnail"] as? String ?? ""
        small_thumbnail                = data?["small_thumbnail"] as? String ?? ""
        profile_icon_sub_imgs          = data?["profile_icon_sub_imgs"] as? [String] ?? []
        sub_thumbnails                 = data?["sub_thumbnails"] as? [String] ?? []
        profile_header_image           = data?["profile_header_image"] as? String ?? ""
        profile_status                 = data?["profile_status"] as? String ?? ""
        note                           = data?["note"] as? String ?? ""
        address                        = data?["address"] as? String ?? ""
        address2                       = data?["address2"] as? String ?? ""
        hobbies                        = data?["hobbies"] as? [String] ?? [String]()
        peerId                         = data?["peerId"] as? String ?? ""
        fcmToken                       = data?["fcmToken"] as? String ?? ""
        deviceToken                    = data?["deviceToken"] as? String ?? ""
        is_approached_notification     = data?["is_approached_notification"] as? Bool ?? true
        is_matching_notification       = data?["is_matching_notification"] as? Bool ?? true
        is_message_notification        = data?["is_message_notification"] as? Bool ?? true
        is_room_phone_notification     = data?["is_room_phone_notification"] as? Bool ?? true
        is_visitor_notification        = data?["is_visitor_notification"] as? Bool ?? true
        is_board_reaction_notification = data?["is_board_reaction_notification"] as? Bool ?? true
        is_with_image_notification     = data?["is_with_image_notification"] as? Bool ?? true
        is_approached_mail             = data?["is_approached_mail"] as? Bool ?? true
        is_matching_mail               = data?["is_matching_mail"] as? Bool ?? true
        is_message_mail                = data?["is_message_mail"] as? Bool ?? true
        is_visitor_mail                = data?["is_visitor_mail"] as? Bool ?? true
        is_board_reaction_mail         = data?["is_board_reaction_mail"] as? Bool ?? true
        is_identification_approval     = data?["is_identification_approval"] as? Bool ?? false
        is_vibration_notification      = data?["is_vibration_notification"] as? Bool ?? true
        is_deleted                     = data?["is_deleted"] as? Bool ?? false
        is_activated                   = data?["is_activated"] as? Bool ?? true
        is_logined                     = data?["is_logined"] as? Bool ?? false
        is_init_reviewed               = data?["is_init_reviewed"] as? Bool ?? false
        is_reviewed                    = data?["is_reviewed"] as? Bool ?? false
        is_rested                      = data?["is_rested"] as? Bool ?? false
        is_withdrawal                  = data?["is_withdrawal"] as? Bool ?? false
        is_tutorial                    = data?["is_tutorial"] as? Bool ?? false
        tutorial_num                   = data?["tutorial_num"] as? Int ?? 0
        is_talkguide                   = data?["is_talkguide"] as? Bool ?? true
        is_auto_message                = data?["is_auto_message"] as? Bool ?? true
        is_display_ranking_talkguide   = data?["is_display_ranking_talkguide"] as? Bool ?? false
        is_friend_emoji                = data?["is_friend_emoji"] as? Bool ?? true
        is_already_auto_matched        = data?["is_already_auto_matched"] as? Bool ?? false
        is_solicitation_agreement      = data?["is_solicitation_agreement"] as? Bool ?? false
        approaches                     = data?["approaches"] as? [String] ?? [String]()
        approacheds                    = data?["approached"] as? [String] ?? [String]()
        reply_approacheds              = data?["reply_approacheds"] as? [String] ?? [String]()
        blocks                         = data?["blocks"] as? [String] ?? [String]()
        violations                     = data?["violations"] as? [String] ?? [String]()
        stops                          = data?["stops"] as? [String] ?? [String]()
        logouted_at                    = data?["logouted_at"] as? Timestamp ?? Timestamp()
        created_at                     = data?["created_at"] as? Timestamp ?? Timestamp()
        updated_at                     = data?["updated_at"] as? Timestamp ?? Timestamp()
        note_updated_at                = data?["note_updated_at"] as? Timestamp
        min_age_filter                 = data?["min_age_filter"] as? Int ?? 12
        max_age_filter                 = data?["max_age_filter"] as? Int ?? 120
        address_filter                 = data?["address_filter"] as? [String] ?? [String]()
        hobby_filter                   = data?["hobby_filter"] as? [String] ?? [String]()
    }
    
    init(cardUser: CardUser) {
        uid                            = cardUser.uid
        phone_number                   = cardUser.phone_number
        nick_name                      = cardUser.nick_name
        type                           = cardUser.type
        holiday                        = cardUser.holiday
        business                       = cardUser.business
        income                         = cardUser.income
        email                          = cardUser.email
        gender                         = cardUser.gender
        violation_count                = cardUser.violation_count
        birth_date                     = cardUser.birth_date
        age                            = cardUser.age
        profile_icon_img               = cardUser.profile_icon_img
        thumbnail                      = cardUser.thumbnail
        small_thumbnail                = cardUser.small_thumbnail
        profile_icon_sub_imgs          = cardUser.profile_icon_sub_imgs
        sub_thumbnails                 = cardUser.sub_thumbnails
        profile_header_image           = cardUser.profile_header_image
        profile_status                 = cardUser.profile_status
        note                           = cardUser.note
        address                        = cardUser.address
        address2                       = cardUser.address2
        hobbies                        = cardUser.hobbies
        peerId                         = cardUser.peerId
        fcmToken                       = cardUser.fcmToken
        deviceToken                    = cardUser.deviceToken
        is_vibration_notification      = cardUser.is_vibration_notification
        is_identification_approval     = cardUser.is_identification_approval
        is_deleted                     = cardUser.is_deleted
        is_activated                   = cardUser.is_activated
        is_logined                     = cardUser.is_logined
        is_reviewed                    = cardUser.is_reviewed
        is_rested                      = cardUser.is_rested
        is_withdrawal                  = cardUser.is_withdrawal
        is_talkguide                   = cardUser.is_talkguide
        approaches                     = cardUser.approaches
        approacheds                    = cardUser.approacheds
        reply_approacheds              = cardUser.reply_approacheds
        min_age_filter                 = cardUser.min_age_filter
        max_age_filter                 = cardUser.max_age_filter
        address_filter                 = cardUser.address_filter
        hobby_filter                   = cardUser.hobby_filter
        logouted_at                    = Timestamp(date: cardUser.logouted_at)
        created_at                     = Timestamp(date: cardUser.created_at)
        updated_at                     = Timestamp(date: cardUser.updated_at)
        notification_email             = ""
        is_approached_notification     = false
        is_matching_notification       = false
        is_message_notification        = false
        is_room_phone_notification     = false
        is_visitor_notification        = false
        is_board_reaction_notification = false
        is_with_image_notification     = false
        is_approached_mail             = false
        is_matching_mail               = false
        is_message_mail                = false
        is_visitor_mail                = false
        is_board_reaction_mail         = false
        is_tutorial                    = false
        tutorial_num                   = 0
        is_auto_message                = false
        is_friend_emoji                = false
        is_init_reviewed               = false
        is_already_auto_matched        = cardUser.is_already_auto_matched
        is_solicitation_agreement      = cardUser.is_solicitation_agreement
        note_updated_at                = self.getNoteUpdatedAt(cardUser)
    }
    
    init(cardUserQuery: SearchResultHit<CardUserQuery>) {
        let cardUserQueryDocument      = cardUserQuery.document
        uid                            = cardUserQueryDocument?.uid ?? ""
        nick_name                      = cardUserQueryDocument?.nick_name ?? ""
        type                           = cardUserQueryDocument?.type ?? ""
        holiday                        = cardUserQueryDocument?.holiday ?? ""
        business                       = cardUserQueryDocument?.business ?? ""
        income                         = cardUserQueryDocument?.income ?? 0
        violation_count                = cardUserQueryDocument?.violation_count ?? 0
        birth_date                     = cardUserQueryDocument?.birth_date ?? ""
        age                            = cardUserQueryDocument?.age ?? 0
        profile_icon_img               = cardUserQueryDocument?.profile_icon_img ?? ""
        thumbnail                      = cardUserQueryDocument?.thumbnail ?? ""
        small_thumbnail                = cardUserQueryDocument?.small_thumbnail ?? ""
        profile_icon_sub_imgs          = cardUserQueryDocument?.profile_icon_sub_imgs ?? [String]()
        sub_thumbnails                 = cardUserQueryDocument?.sub_thumbnails ?? [String]()
        profile_header_image           = cardUserQueryDocument?.profile_header_image ?? ""
        profile_status                 = cardUserQueryDocument?.profile_status ?? ""
        note                           = cardUserQueryDocument?.note ?? ""
        address                        = cardUserQueryDocument?.address ?? ""
        address2                       = cardUserQueryDocument?.address2 ?? ""
        hobbies                        = cardUserQueryDocument?.hobbies ?? [String]()
        is_deleted                     = cardUserQueryDocument?.is_deleted ?? false
        is_activated                   = cardUserQueryDocument?.is_activated ?? true
        is_logined                     = cardUserQueryDocument?.is_logined ?? false
        is_rested                      = cardUserQueryDocument?.is_rested ?? false
        approacheds                    = cardUserQueryDocument?.approached ?? [String]()
        phone_number                   = ""
        email                          = ""
        notification_email             = ""
        gender                         = 0
        peerId                         = ""
        fcmToken                       = ""
        deviceToken                    = ""
        is_approached_notification     = false
        is_matching_notification       = false
        is_message_notification        = false
        is_room_phone_notification     = false
        is_visitor_notification        = false
        is_board_reaction_notification = false
        is_with_image_notification     = false
        is_approached_mail             = false
        is_matching_mail               = false
        is_message_mail                = false
        is_visitor_mail                = false
        is_board_reaction_mail         = false
        is_vibration_notification      = false
        is_identification_approval     = false
        is_init_reviewed               = false
        is_reviewed                    = false
        is_withdrawal                  = false
        is_tutorial                    = false
        tutorial_num                   = 0
        is_talkguide                   = false
        is_auto_message                = false
        is_friend_emoji                = false
        is_already_auto_matched        = cardUserQueryDocument?.is_already_auto_matched ?? false
        is_solicitation_agreement      = cardUserQueryDocument?.is_solicitation_agreement ?? false
        approaches                     = [String]()
        reply_approacheds              = [String]()
        min_age_filter                 = 12
        max_age_filter                 = 120
        address_filter                 = [String]()
        hobby_filter                   = [String]()
        let logouted_at_int            = cardUserQueryDocument?.logouted_at ?? 0
        let created_at_int             = cardUserQueryDocument?.created_at ?? 0
        let updated_at_int             = cardUserQueryDocument?.updated_at ?? 0
        let logouted_at_date           = logouted_at_int.dateFromInt()
        let created_at_date            = created_at_int.dateFromInt()
        let updated_at_date            = updated_at_int.dateFromInt()
        logouted_at                    = Timestamp(date: logouted_at_date)
        created_at                     = Timestamp(date: created_at_date)
        updated_at                     = Timestamp(date: updated_at_date)
        note_updated_at                = self.getNoteUpdatedAt(cardUserQueryDocument)
    }
    
    init(cardUserQuery: CardUserQuery) {
        uid                            = cardUserQuery.uid ?? ""
        nick_name                      = cardUserQuery.nick_name ?? ""
        type                           = cardUserQuery.type ?? ""
        holiday                        = cardUserQuery.holiday ?? ""
        business                       = cardUserQuery.business ?? ""
        income                         = cardUserQuery.income ?? 0
        violation_count                = cardUserQuery.violation_count ?? 0
        birth_date                     = cardUserQuery.birth_date ?? ""
        age                            = cardUserQuery.age ?? 0
        profile_icon_img               = cardUserQuery.profile_icon_img ?? ""
        thumbnail                      = cardUserQuery.thumbnail ?? ""
        small_thumbnail                = cardUserQuery.small_thumbnail ?? ""
        profile_icon_sub_imgs          = cardUserQuery.profile_icon_sub_imgs ?? [String]()
        sub_thumbnails                 = cardUserQuery.sub_thumbnails ?? [String]()
        profile_header_image           = cardUserQuery.profile_header_image ?? ""
        profile_status                 = cardUserQuery.profile_status ?? ""
        note                           = cardUserQuery.note ?? ""
        address                        = cardUserQuery.address ?? ""
        address2                       = cardUserQuery.address2 ?? ""
        hobbies                        = cardUserQuery.hobbies ?? [String]()
        is_deleted                     = cardUserQuery.is_deleted ?? false
        is_activated                   = cardUserQuery.is_activated ?? true
        is_logined                     = cardUserQuery.is_logined ?? false
        is_rested                      = cardUserQuery.is_rested ?? false
        approacheds                    = cardUserQuery.approached ?? [String]()
        phone_number                   = ""
        email                          = ""
        notification_email             = ""
        gender                         = 0
        peerId                         = ""
        fcmToken                       = ""
        deviceToken                    = ""
        is_approached_notification     = false
        is_matching_notification       = false
        is_message_notification        = false
        is_room_phone_notification     = false
        is_visitor_notification        = false
        is_board_reaction_notification = false
        is_with_image_notification     = false
        is_approached_mail             = false
        is_matching_mail               = false
        is_message_mail                = false
        is_visitor_mail                = false
        is_board_reaction_mail         = false
        is_vibration_notification      = false
        is_identification_approval     = false
        is_init_reviewed               = false
        is_reviewed                    = false
        is_withdrawal                  = false
        is_tutorial                    = false
        tutorial_num                   = 0
        is_talkguide                   = false
        is_auto_message                = false
        is_friend_emoji                = false
        is_already_auto_matched        = cardUserQuery.is_already_auto_matched ?? false
        is_solicitation_agreement      = cardUserQuery.is_solicitation_agreement ?? false
        approaches                     = [String]()
        reply_approacheds              = [String]()
        min_age_filter                 = 12
        max_age_filter                 = 120
        address_filter                 = [String]()
        hobby_filter                   = [String]()
        let logouted_at_int            = cardUserQuery.logouted_at ?? 0
        let created_at_int             = cardUserQuery.created_at ?? 0
        let updated_at_int             = cardUserQuery.updated_at ?? 0
        let logouted_at_date           = logouted_at_int.dateFromInt()
        let created_at_date            = created_at_int.dateFromInt()
        let updated_at_date            = updated_at_int.dateFromInt()
        logouted_at                    = Timestamp(date: logouted_at_date)
        created_at                     = Timestamp(date: created_at_date)
        updated_at                     = Timestamp(date: updated_at_date)
        note_updated_at                = self.getNoteUpdatedAt(cardUserQuery)
    }
    
    private func getNoteUpdatedAt(_ cardUserQuery: CardUserQuery?) -> Timestamp? {
        if let note_updated_at_int = cardUserQuery?.note_updated_at {
            let note_updated_at_date = note_updated_at_int.dateFromInt()
            return Timestamp(date: note_updated_at_date)
        } else {
            return nil
        }
    }
    
    private func getNoteUpdatedAt(_ cardUser: CardUser) -> Timestamp? {
        if let note_updated_at_date = cardUser.note_updated_at {
            return Timestamp(date: note_updated_at_date)
        } else {
            return nil
        }
    }
}
