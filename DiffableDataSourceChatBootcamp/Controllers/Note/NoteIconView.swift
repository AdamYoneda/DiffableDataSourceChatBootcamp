//
//  NoteIconView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2024/01/29.
//

import UIKit

final class NoteIconView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var addIconView: UIView!
    @IBOutlet weak var addIconContainerView: UIView!
    @IBOutlet var addIconBubbleViews: [UIView]!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet var noteBubbleViews: [UIView]!
    @IBOutlet weak var noteContainerView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        setUp()
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
        setUp()
        configure()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("NoteIconView", owner: self, options: nil)
        contentView.fixInView(self)
    }
    
    private func setUp() {
        iconImageView.clipsToBounds = true
        iconImageView.rounded()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = .systemGray6
        addIconContainerView.rounded()
        addIconContainerView.setCustomShadow(opacity: 0.5, color: .accentColor, width: 0, height: 0, shadowRadius: 2.0)
        addIconBubbleViews.forEach {
            $0.rounded()
            $0.setCustomShadow(opacity: 0.5, color: .accentColor, width: 0, height: 0, shadowRadius: 1.0)
        }
        
        noteBubbleViews.forEach {
            $0.rounded()
            $0.setCustomShadow(opacity: 0.3, color: .black, width: 0, height: 0, shadowRadius: 2.0)
        }
        noteContainerView.rounded()
        noteContainerView.setCustomShadow(opacity: 0.2, color: .black, width: 0, height: 0, shadowRadius: 3.0)
    }
    
    func configure() {
        if let loginUser = GlobalVar.shared.loginUser {
            iconImageView.setImage(withURLString: loginUser.profile_icon_img)
            
            if loginUser.note.isEmpty {
                addIconView.isHidden = false
                noteView.isHidden = true
            } else {
                addIconView.isHidden = true
                noteView.isHidden = false
                noteLabel.text = loginUser.note
                noteLabel.sizeToFit()
            }
        }
        self.layoutIfNeeded()
    }
}
