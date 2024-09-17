
import UIKit

extension UIView {
    
    @objc class var identifier: String {
        return String(describing: self)
    }
    
    func setShadow(opacity: Float = 0.1, color: UIColor = .black) {
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
    }
    
    func setCustomShadow(opacity: Float = 0.1, color: UIColor = .black, width: Double = 0.0, height: Double = 20.0, shadowRadius: CGFloat = 5.0) {
        // 影の方向（width=右方向、height=下方向）
        self.layer.shadowOffset = CGSize(width: width, height: height)
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = shadowRadius
    }
    
    func setBorder() {
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
    }
    
    func rounded() {
        layer.cornerRadius = bounds.height / 2
    }
    
    func customTop() {
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    func customBottom() {
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
    func allMaskedCorners() {
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }
    // サブビューを全て削除
    func removeAllSubviews(){
        subviews.forEach({ $0.removeFromSuperview() })
    }
}

extension UIView {
    func fixInView(_ container: UIView) -> Void{
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.frame = container.frame;
        container.addSubview(self);
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}
