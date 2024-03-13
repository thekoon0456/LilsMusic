//
//  UIVIewController+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

extension UIViewController {
    
    func setGradient(startColor: CGColor?, endColor: CGColor?) {
        let gradientLayer = CAGradientLayer()
        let startColor = startColor?.copy(alpha: 1.0) ?? CGColor(gray: 0, alpha: 0)
        let endColor = endColor?.copy(alpha: 0.5) ?? CGColor(gray: 0, alpha: 0)
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
