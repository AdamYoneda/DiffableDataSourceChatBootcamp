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
}
