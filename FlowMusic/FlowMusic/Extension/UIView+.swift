//
//  UIView+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

extension UIView {
    
    func addSubviews(_ subviews: UIView...) {
        for subview in subviews {
            addSubview(subview)
        }
    }
}

extension UIView {
    func addShadow(color: UIColor = .label,
                   offset: CGSize = CGSize(width: 0, height: 1),
                   opacity: Float = 0.5,
                   radius: CGFloat = 3) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
    
//    func setShadow() {
//        layer.masksToBounds = fa
//        layer.shadowOpacity = 0.5
//        layer.shadowOffset = .init(width: 0, height: 0)
//        layer.shadowColor = UIColor.label.cgColor
//        layer.shadowRadius = 5
//        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
//    }
}
