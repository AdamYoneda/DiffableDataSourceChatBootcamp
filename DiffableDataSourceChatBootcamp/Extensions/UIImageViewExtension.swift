//
//  UIImageViewExtension.swift
//  Tauch
//
//  Created by Apple on 2022/06/14.
//

import UIKit
import Nuke
import NukeExtensions

extension UIImageView {
    //グラデーション付きの影をつける
    func setGradationShadow() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        let cgRect = CGRect(x: 0, y:  frame.height - 100, width: frame.width, height: 100)
        gradientLayer.frame = cgRect
        layer.insertSublayer(gradientLayer, at:0)
    }
    
    func setImage(withURLString urlString: String, isFade: Bool = true) {
        if let url = URL(string: urlString) {
            loadImage(with: ImageRequest(url: url), into: self)
        }
    }
    
    func setImage(withURL url: URL, isFade: Bool = true) {
        loadImage(with: ImageRequest(url: url), into: self)
    }
}
