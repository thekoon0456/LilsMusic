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
    func addShadow(color: UIColor = .label, offset: CGSize = CGSize(width: 1, height: 1), opacity: Float = 0.5, radius: CGFloat = 1) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
    }
}
