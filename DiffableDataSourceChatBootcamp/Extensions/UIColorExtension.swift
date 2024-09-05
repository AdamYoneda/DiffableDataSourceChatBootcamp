//
//  UIColorExtension.swift
//  Tauch
//
//  Created by Apple on 2022/07/30.
//

import UIKit

extension UIColor {
    
    static let accentColor = UIColor(red: 255/255, green: 153/255, blue: 102/255, alpha: 1)
    static let lightColor = UIColor(red: 255/255, green: 229/255, blue: 204/255, alpha: 1)
    static let lightSecColor = UIColor(red: 255/255, green: 247/255, blue: 242/255, alpha: 1)
    static let fontColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
    static let lightPinkColor = UIColor(red: 255/255, green: 182/255, blue: 193/255, alpha: 0.3)
    static let messageHightLightColor = UIColor(red: 249/255, green: 102/255, blue: 102/255, alpha: 1.0)
    static let skyblueColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 1.0)
    static let blueAccentColor = UIColor(red: 136/255, green: 203/255, blue: 206/255, alpha: 1)
    static let disableColor = UIColor(red: 228/255, green: 225/255, blue: 222/255, alpha: 1.0)
    static let categoryFriendColor = UIColor(red: 137/255, green: 196/255, blue: 172/255, alpha: 1.0)
   
    static let categoryWorriesColor = UIColor(red: 110/255, green: 188/255, blue: 197/255, alpha: 1.0)
    static let categoryHumorColor = UIColor(red: 255/255, green: 200/255, blue: 0/255, alpha: 1.0)
    static let categoryTeaserColor = UIColor(red: 222/255, green: 173/255, blue: 202/255, alpha: 1.0)
    static let categoryTweetColor = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1.0)
    // static let categoryTweetColor = UIColor(red: 255/255, green: 235/255, blue: 165/255, alpha: 1.0)
    static let selectedMyMessageColor = UIColor(red: 204/255, green: 132/255, blue: 98/255, alpha: 1.0)
    static let selectedOtherMessageColor = UIColor(red: 195/255, green: 195/255, blue: 198/255, alpha: 1.0)
    static let textViewColor = UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1.0)
    
    struct MessageColor {
        static let cellPink = UIColor(red: 244/255, green: 219/255, blue: 219/255, alpha: 1)
        static let lightPink = UIColor(red: 250/255, green: 242/255, blue: 244/255, alpha: 1)
        static let standardPink = UIColor(red: 230/255, green: 173/255, blue: 176/255, alpha: 1)
        static let heavyPink = UIColor(red: 162/255, green: 95/255, blue: 105/255, alpha: 1)
    }
    
    func setColor(colorType: String, alpha: CGFloat) -> UIColor {
        // デフォルトカラー (白色)
        var color = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: alpha)
        switch colorType {
        case "thinWhiteColor":
            color = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: alpha)
            break
        case "fontColor":
            color = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: alpha)
            break
        case "accentColor":
            color = UIColor(red: 255/255, green: 153/255, blue: 102/255, alpha: alpha)
            break
        case "lightColor":
            color = UIColor(red: 255/255, green: 224/255, blue: 209/255, alpha: alpha)
            break
        case "blueColor":
            color = UIColor(red: 29/255, green: 161/255, blue: 241/255, alpha: alpha)
            break
        case "greyColor":
            color = UIColor(red: 221/255, green: 221/255, blue: 221/255, alpha: alpha)
            break
        case "pinkColor":
            color = UIColor(red: 249/255, green: 24/255, blue: 128/255, alpha: alpha)
            break
        case "darkPinkColor":
            color = UIColor(red: 210/255, green: 53/255, blue: 124/255, alpha: alpha)
            break
        case "yellowColor":
            color = UIColor(red: 255/255, green: 210/255, blue: 76/255, alpha: alpha)
        case "blackColor":
            color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: alpha)
            break
        default:
            color = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: alpha)
            break
        }
        return color
    }
    
    /// 色をUIImageに変換
    var image: UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(self.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
