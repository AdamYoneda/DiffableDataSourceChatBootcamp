//
//  MessagePopoverBackgroundView.swift
//  Tauch
//
//  Created by Adam Yoneda on 2023/08/11.
//

import UIKit

final class MessagePopoverBackgroundView: UIPopoverBackgroundView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowOpacity = 0
        setupPathLayer()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first as? UIWindowScene, let window = windowScene.windows.first {
            let transitionViews = window.subviews.filter { String(describing: type(of: $0)) == "UITransitionView" }
            for transitionView in transitionViews {
                let shadowView = transitionView.subviews.filter { String(describing: type(of: $0)) == "_UICutoutShadowView" }.first
                shadowView?.isHidden = true
            }
        }
    }
    
    // MARK: - UIPopoverBackgroundViewMethods
    
    override static func arrowBase() -> CGFloat {
        return 15
    }
    
    override static func arrowHeight() -> CGFloat {
        return 10
    }
    
    override static func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }
    
    // MARK: - UIPopoverBackgroundView properties
    
    private var _arrowOffset: CGFloat = 0
    override var arrowOffset: CGFloat {
        get { return _arrowOffset }
        set { _arrowOffset = newValue }
    }
    
    private var _arrowDirection: UIPopoverArrowDirection = .unknown
    override var arrowDirection: UIPopoverArrowDirection {
        get { return _arrowDirection }
        set { _arrowDirection = newValue }
    }
    
    
    // MARK: - Drawing
    
    /// UIBezierPathで吹き出しを描画する
    private func setupPathLayer() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let rect = bounds
        let pathLayer = CAShapeLayer()
        pathLayer.frame = rect
        pathLayer.path = generatePath(rect).cgPath
        pathLayer.fillColor = UIColor.darkGray.cgColor
        pathLayer.strokeColor = UIColor.darkGray.cgColor
        pathLayer.lineWidth = 1.0
        layer.addSublayer(pathLayer)
    }
    
    private func generatePath(_ rect: CGRect) -> UIBezierPath {
        let insets: UIEdgeInsets = {
            var insets = MessagePopoverBackgroundView.contentViewInsets()
            if _arrowDirection == .up {
                insets.top += MessagePopoverBackgroundView.arrowHeight()
            } else if _arrowDirection == .down {
                insets.bottom += MessagePopoverBackgroundView.arrowHeight()
            }
            return insets
        }()
        
        let arrowBase = MessagePopoverBackgroundView.arrowBase()
        let arrowCenterX = rect.size.width / 2 + _arrowOffset
        
        let path = UIBezierPath()
        if _arrowDirection == .up {
            path.move(to: CGPoint(x: arrowCenterX - arrowBase / 2, y: insets.top))
            path.addLine(to: CGPoint(x: arrowCenterX, y: 0))
            path.addLine(to: CGPoint(x: arrowCenterX + arrowBase / 2, y: insets.top))
            path.addLine(to: CGPoint(x: arrowCenterX - arrowBase / 2, y: insets.top))
        } else if _arrowDirection == .down {
            path.move(to: CGPoint(x: arrowCenterX - arrowBase / 2, y: rect.maxY - insets.bottom))
            path.addLine(to: CGPoint(x: arrowCenterX, y: rect.maxY))
            path.addLine(to: CGPoint(x: arrowCenterX + arrowBase / 2, y: rect.maxY - insets.bottom))
            path.addLine(to: CGPoint(x: arrowCenterX - arrowBase / 2, y: rect.maxY - insets.bottom))
        }
        path.close()
        
        return path
    }
}
