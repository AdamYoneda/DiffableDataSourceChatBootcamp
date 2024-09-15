//
//  UIButtonExtension.swift
//  Tauch
//
//  Created by Musa Yazuju on 2022/06/12.
//

import UIKit

extension UIButton {
    
    func enable(bgColor: UIColor = .accentColor) {
        self.isUserInteractionEnabled = true
        self.backgroundColor = bgColor
    }
    
    func disable() {
        self.isUserInteractionEnabled = false
        self.backgroundColor = .lightGray
    }
    
    func disableColor() {
        self.backgroundColor = .lightGray
    }
    
    //ナビゲーションバー用のボタン
    func changeIntoBarItem(systemImage: String) -> UIBarButtonItem {
        setImage(UIImage(systemName: systemImage), for: .normal)
        frame = CGRect(x: 0, y: 0, width: 30, height: 25)
        imageView?.contentMode = .scaleAspectFit
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        let barItem = UIBarButtonItem(customView: self)
        barItem.customView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
        barItem.customView?.heightAnchor.constraint(equalToConstant: 25).isActive = true
        return barItem
    }
}
