//
//  NotePreviewViewController.swift
//  Tauch
//
//  Created by Adam Yoneda on 2024/01/31.
//

import UIKit

final class NotePreviewViewController: UIBaseViewController {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var noteLabel: UILabel!
    
    private let parentVC: UIViewController?
    
    init(parentViewController: UIViewController, nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
        self.parentVC = parentViewController
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        iconImageView.clipsToBounds = true
        iconImageView.rounded()
        if let loginUser = GlobalVar.shared.loginUser {
            iconImageView.setImage(withURLString: loginUser.profile_icon_img)
        }
        frameView.layer.cornerRadius = 15.0
        shadowView.layer.cornerRadius = 15.0
        shadowView.setCustomShadow(opacity: 0.1, color: .darkGray, width: 0, height: 8, shadowRadius: 12)
        noteLabel.text = GlobalVar.shared.loginUser?.note
    }

    @IBAction func donePressed(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func inputNewNote(_ sender: UIButton) {
        super.dismiss(animated: true) {
            let inputVC = UINavigationController(rootViewController: InputNoteViewController())
            inputVC.modalPresentationStyle = .overFullScreen
            self.parentVC?.present(inputVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteNote(_ sender: UIButton) {
        if let uid = GlobalVar.shared.loginUser?.uid {
            db.collection("users").document(uid).updateData(["note": ""]) { [weak self] error in
                guard let self, error == nil else {
                    self?.alertWithDismiss(title: "失敗", message: "ひとことの削除に失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                    return
                }
                GlobalVar.shared.loginUser?.note = ""
                MessageListViewController.noteIconView?.configure()
                dismiss(animated: true)
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            GlobalVar.shared.thisClassName = "MessageListViewController" // 「やりとり」画面に戻る導線しかないので、ここで更新
        }
    }
}
