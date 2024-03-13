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

extension UIAlertController {

    func appendingAction(
        title: String?,
        style: UIAlertAction.Style = .default,
        handler: (() -> Void)? = nil
    ) -> Self {
        let alertAction = UIAlertAction(title: title, style: style) { _ in handler?() }
        
        self.addAction(alertAction)
        return self
    }
    
    func appendingCancel() -> Self {
        return self.appendingAction(title: "취소", style: .cancel)
    }
}
