//
//  UIViewContrllerExtension.swift
//  DiffableDataSourceChatBootcamp
//
//  Created by Adam Yoneda on 2024/09/08.
//

import UIKit
import Foundation

extension UIViewController {
    
    // アラート表示
    func alert(title: String, message: String, actiontitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actiontitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // OKボタン後のモーダルを閉じるアラート表示
    func alertWithDismiss(title: String, message: String, actiontitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actiontitle, style: .default, handler: {
            [weak self] (action: UIAlertAction!) -> Void in
            guard let weakSelf = self else { return }
            weakSelf.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // ローディング画面を表示
    func showLoadingView(_ loadingView: UIView, color: UIColor = .gray) {
        
        loadingView.backgroundColor = .white.withAlphaComponent(0.5)
        let indicator = UIActivityIndicatorView()
        indicator.center = loadingView.center
        indicator.style = .large
        indicator.color = color
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        guard let windowFirst = AppDelegate().window else { return }
        
        windowFirst.addSubview(loadingView)
    }
    
    // 確認ダイアログ
    func dialog(title: String, subTitle: String, confirmTitle: String, completion: @escaping (Bool) -> Void) {
        //UIAlertControllerのスタイルがalert
        let alert: UIAlertController = UIAlertController(title: title, message:  subTitle, preferredStyle:  UIAlertController.Style.alert)
        // 継続処理
        let confirmAction: UIAlertAction = UIAlertAction(title: confirmTitle, style: UIAlertAction.Style.default, handler:{
            [weak self] (action: UIAlertAction!) -> Void in
            guard let _ = self else { return }
            completion(true)
        })
        // キャンセル処理
        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
            [weak self] (action: UIAlertAction!) -> Void in
            guard let _ = self else { return }
            completion(false)
        })
        // UIAlertControllerに継続とキャンセル時のActionを追加
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true, completion: nil)
    }
}
