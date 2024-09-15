//
//  MessageRoomTitleView.swift
//
//  Created by Adam Yoneda on 2023/09/09.
//

import UIKit

final class MessageRoomTitleView: UIView {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
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
        
        iconImageView.layer.borderColor = UIColor.white.cgColor
        nameLabel.textColor = .white
    }
}
