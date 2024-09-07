//
//  MessageRoomTitleView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/09/09.
//

import UIKit

final class MessageRoomTitleView: UIView {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var consectiveCountLabel: UILabel!
    @IBOutlet weak var editNameButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    private func loadNib() {
        if let view = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    func configure(room: Room, partnerUser: User, limitIconEnabled: Bool) {
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = iconImageView.bounds.width / 2 + 2.5
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.setImage(withURLString: partnerUser.profile_icon_img)
        iconImageView.layer.borderWidth = 2.5
        
        nameLabel.text = (room.partnerNickname?.isEmpty == false && room.partnerNickname != nil) ? room.partnerNickname : partnerUser.nick_name
        nameLabel.adjustsFontSizeToFitWidth = true
        
        let count = getConsectiveCount(room)
        if count >= 5 && GlobalVar.shared.loginUser?.is_friend_emoji == true {
            if limitIconEnabled {
                consectiveCountLabel.isHidden = false
                consectiveCountLabel.text = "⌛️"
            } else {
                if let image = UIImage(systemName: "flame.fill") {
                    let imageAttachment = NSTextAttachment(image: image)
                    let text = NSMutableAttributedString(attachment: imageAttachment)
                    text.append(NSAttributedString(string: String(count)))
                    
                    consectiveCountLabel.isHidden = false
                    consectiveCountLabel.attributedText = text
                }
            }
        } else {
            consectiveCountLabel.isHidden = true
        }
        
        switch room.roomStatus {
        case .normal:
            iconImageView.layer.borderColor = UIColor.white.cgColor
            nameLabel.textColor = .white
            consectiveCountLabel.textColor = .white
        case .sBest:
            iconImageView.layer.borderColor = UIColor.white.cgColor
            nameLabel.textColor = UIColor.MessageColor.standardPink
            consectiveCountLabel.textColor = UIColor.MessageColor.standardPink
        case .ssBest, .sssBest:
            iconImageView.layer.borderColor = UIColor.white.cgColor
            nameLabel.textColor = .white
            consectiveCountLabel.textColor = .white
            editNameButton.configuration?.baseForegroundColor = .white
        }
    }
    
    private func getConsectiveCount(_ room: Room) -> Int {
        guard let roomId = room.document_id else { return 0 }
        guard let count = GlobalVar.shared.consectiveCountDictionary[roomId] else { return 0 }
        
        return count
    }
}
