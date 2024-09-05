//
//  InputNoteViewController.swift
//  Tauch
//
//  Created by Adam Yoneda on 2024/01/29.
//

import UIKit
import FirebaseFirestore

final class InputNoteViewController: UIBaseViewController {
    
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    
    private var textLength: Int = 0 {
        didSet {
            if textLength != 0 {
                self.navigationItem.rightBarButtonItem?.tintColor = .accentColor
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                self.navigationItem.rightBarButtonItem?.tintColor = .lightGray
                self.navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
    }
    private let maxTextLength: Int = 15
    private var inputText: String = "" {
        didSet {
            textLength = inputText.count
        }
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
        shadowView.setCustomShadow(opacity: 0.2, color: .black, width: 0, height: 8, shadowRadius: 10)
        inputTextField.delegate = self
        
        // ナビゲーションバーを表示する
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        // ナビゲーションの戻るボタンを消す
        self.navigationItem.setHidesBackButton(true, animated: true)
        // ナビゲーションバーの透過させる
        self.navigationController?.navigationBar.isTranslucent = true
        //ナビゲーションアイテムのタイトルを設定
        self.navigationItem.title = "新しいひとこと"
        // ナビゲーションバー設定
        hideNavigationBarBorderAndShowTabBarBorder()
        //ナビゲーションバー左ボタンを設定
        let backImage = UIImage(systemName: "xmark")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(cancel))
        self.navigationItem.leftBarButtonItem?.tintColor = .fontColor
        self.navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        //ナビゲーションバー右ボタンを設定
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "シェア", style: .plain, target: self, action: #selector(confirm))
        self.navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.navigationItem.rightBarButtonItem?.tintColor = .lightGray
        self.navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        inputTextField.becomeFirstResponder()
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }
    
    @objc private func confirm() {
        if let inputText = inputTextField.text, let uid = GlobalVar.shared.loginUser?.uid {
            GlobalVar.shared.loginUser?.note = inputText
            MessageListViewController.noteIconView?.configure()
            db.collection("users").document(uid).updateData(["note": inputText, "note_updated_at": Timestamp()]) { [weak self] error in
                guard let self, error == nil else {
                    self?.alertWithDismiss(title: "失敗", message: "ひとことのシェアに失敗しました。時間をおいて再度お試しください。", actiontitle: "OK")
                    return
                }
                dismiss(animated: true)
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            GlobalVar.shared.thisClassName = "MessageListViewController" // 「やりとり」画面に戻る導線しかないので、ここで更新
        }
    }
    
    //MARK: UITextFieldDelegate

    // 最大文字数を設定, 入力したテキストの保存
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else { return }
        // 最大文字数を設定
        if text.count > maxTextLength {
            inputTextField.text = String(text.prefix(maxTextLength))
        }
        // 半角・全角スペースの排除
        let whiteSpaces: CharacterSet = [" ", "　"]
        let trimmedText = text.trimmingCharacters(in: whiteSpaces)
        // テキストの保存
        inputText = trimmedText
    }
    
    // Returnを押すと編集が終わる（キーボードが閉じる）
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
                            
    // 入力したテキストの一時的な保存、文字数カウント
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = textField.text else { return true }
        // 半角・全角スペースの排除
        let whiteSpaces: CharacterSet = [" ", "　"]
        let trimmedText = text.trimmingCharacters(in: whiteSpaces)
        guard !trimmedText.isEmpty else { return true }
        // 文字数カウント
        let newLength = trimmedText.utf16.count + string.utf16.count - range.length
        if newLength <= maxTextLength {
            textLength = newLength
            countLabel.text = "\(textLength)/\(maxTextLength)"
        }
        return newLength <= maxTextLength
    }
}
