//
//  NoteBubbleView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2024/02/02.
//

import UIKit

final class NoteBubbleView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var textContainerView: UIView!
    @IBOutlet weak var firstBubbleView: UIView!
    @IBOutlet weak var secondBubbleView: UIView!
    @IBOutlet weak var thirdBubbleView: UIView!
    
    override func draw(_ rect: CGRect) {
        textContainerView.rounded()
        firstBubbleView.rounded()
        firstBubbleView.setCustomShadow(opacity: 0.3, color: .black, width: 0, height: 2, shadowRadius: 2.0)
        secondBubbleView.rounded()
        secondBubbleView.setCustomShadow(opacity: 0.3, color: .black, width: 0, height: 2, shadowRadius: 2.0)
        thirdBubbleView.rounded()
        thirdBubbleView.setCustomShadow(opacity: 0.3, color: .black, width: 0, height: 2, shadowRadius: 2.0)
    }
    
    init(text: String) {
        super.init(frame: CGRectZero)
        commonInit()
        textLabel.text = text
        textLabel.sizeToFit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("NoteBubbleView", owner: self, options: nil)
        contentView.fixInView(self)
    }
    
    func setBubbleColor(isNewNote: Bool) {
        if isNewNote {
            textContainerView.setCustomShadow(opacity: 0.8, color: .systemGreen, width: 0, height: 0, shadowRadius: 3.0)
        } else {
            textContainerView.setCustomShadow(opacity: 0.2, color: .black, width: 0, height: 0, shadowRadius: 3.0)
        }
    }
}
