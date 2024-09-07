//
//  UIViewContrllerExtension.swift
//  DiffableDataSourceChatBootcamp
//
//  Created by Adam Yoneda on 2024/09/08.
//

import UIKit

extension UIViewController {
    
    // アラート表示
    func alert(title: String, message: String, actiontitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actiontitle, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
