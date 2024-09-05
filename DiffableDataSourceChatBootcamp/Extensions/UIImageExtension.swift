//
//  UIImageViewExtension.swift
//  Tauch
//
//  Created by Musa Yazuju on 2022/06/07.
//

import UIKit

extension UIImage {
    //サイズを変える
    func resize(targetSize: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size:targetSize).image { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    //画像圧縮
    func compress() -> UIImage {
        guard let compressedImage = self.jpegData(compressionQuality: 0.7) else { return UIImage() }
        guard let compressedUIImage = UIImage(data: compressedImage) else { return UIImage() }
        return compressedUIImage
    }
    //サイズを変える
    func resized(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio

        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
    
    func resizeImage(withPercentage percentage: CGFloat) -> UIImage? {
        // 圧縮後のサイズ情報
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        // 圧縮画像を返す
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image { _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    
    func ImageToString() -> String? {
        // 画像をDataに変換
        guard let uploadImage = self.jpegData(compressionQuality: 0.05) else { return nil }
        // BASE64のStringに変換する
        let encodeString: String = uploadImage.base64EncodedString(options: .lineLength64Characters)
        return encodeString
    }
}
