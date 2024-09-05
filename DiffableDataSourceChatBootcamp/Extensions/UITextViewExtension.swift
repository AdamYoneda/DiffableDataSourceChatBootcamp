//
//  UIView+Extension.swift
//  Tauch
//
//  Created by Musa Yazuju on 2022/06/05.
//

import UIKit

extension UITextView {
    
    func addHyperLinksToText(originalText: String, hyperLinks: [String: String]) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributedOriginalText = NSMutableAttributedString(string: originalText)
        for (hyperLink, urlString) in hyperLinks {
            let linkRange = attributedOriginalText.mutableString.range(of: hyperLink)
            let fullRange = NSRange(location: 0, length: attributedOriginalText.length)
            attributedOriginalText.addAttribute(NSAttributedString.Key.link, value: urlString, range: linkRange)
            attributedOriginalText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: fullRange)
        }
        self.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor().setColor(colorType: "accentColor", alpha: 1.0),
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        self.attributedText = attributedOriginalText
    }
    
    func setToolbar(action: Selector?) {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 45))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: action)
        toolbar.setItems([spacelItem, doneItem], animated: true)
        inputAccessoryView = toolbar
    }
}
