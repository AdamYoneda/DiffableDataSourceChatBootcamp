
import UIKit

struct MessageSendModel {
    let text: String
    let inputType: MessageInputType
    var messageType: CustomMessageType
    let sourceType: UIImagePickerController.SourceType?
    let imageUrls: [String]?
    let sticker: UIImage?
    let stickerIdentifier: String?
    var messageId: String
    let replyMessageId: String?
    let replyMessageText: String?
    let replyMessageCreator: String?
    let replyMessageImageUrls: [String]?
    let replyMessageType: CustomMessageType?
}
