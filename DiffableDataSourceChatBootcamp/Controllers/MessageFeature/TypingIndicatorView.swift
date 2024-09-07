//
//  TypingIndicatorView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/21.
//

import UIKit
import NVActivityIndicatorView

final class TypingIndicatorView: UIView {

    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    private let room: Room
    
    init(frame: CGRect, room: Room) {
        self.room = room
        super.init(frame: frame)
        loadNib()
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
    
    deinit {
        indicatorView.stopAnimating()
        // print("TypingIndicatorView deinit")
    }

    private func loadNib() {
        if let view = Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            self.addSubview(view)
        }
    }
    
    private func configure() {
        if let partnerUser = room.partnerUser {
            indicatorLabel.text = "\(partnerUser.nick_name)が入力中..."
        } else {
            indicatorLabel.text = "入力中..."
        }
        
        switch room.roomStatus {
        case .normal, .sBest:
            backgroundColor = .white
        case .ssBest:
            backgroundColor = UIColor.MessageColor.lightPink
        case .sssBest:
            backgroundColor = UIColor.MessageColor.lightPink
        }
    }
}
