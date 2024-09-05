//
//  UnsendMessageCollectionViewCell.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/07.
//

import UIKit

final class UnsendMessageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backgroundBaseView: UIView!
    @IBOutlet private weak var unsendLabel: UILabel!
    
    static let nib = UINib(nibName: "UnsendMessageCollectionViewCell", bundle: nil)
    static let nibName = "UnsendMessageCollectionViewCell"
    static let cellIdentifier = "UnsendMessageCollectionViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupLabel()
    }
    
    private func setupLabel() {
        backgroundBaseView.layer.cornerRadius = backgroundBaseView.frame.height / 2
    }
    
    /// ログイン中のユーザー側のメッセージを送信取り消しする場合の設定
    func configure(room: Room?, message: Message) {
        if let loginUser = GlobalVar.shared.loginUser,
           let partnerUser = room?.partnerUser,
           loginUser.uid != message.creator {
            unsendLabel.text = "\(room?.partnerNickname ?? partnerUser.nick_name)がメッセージの送信を取り消しました"
            unsendLabel.sizeToFit()
        } else {
            unsendLabel.text = "メッセージの送信を取り消しました"
            unsendLabel.sizeToFit()
        }
    }
}
