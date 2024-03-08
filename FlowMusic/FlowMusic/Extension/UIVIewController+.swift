//
//  UIVIewController+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

extension UIViewController {
    
    func setGradient(startColor: CGColor?, endColor: CGColor?) {
        // 그라디언트 레이어 생성
        let gradientLayer = CAGradientLayer()
        let startColor = startColor?.copy(alpha: 1.0) ?? CGColor(gray: 0, alpha: 0)
        let endColor = endColor?.copy(alpha: 0.5) ?? CGColor(gray: 0, alpha: 0)
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [startColor, endColor] // 그라디언트 색상 설정
        gradientLayer.startPoint = CGPoint(x: 0, y: 0) // 시작점 설정
        gradientLayer.endPoint = CGPoint(x: 1, y: 1) // 종료점 설정
        
        // UIView의 layer에 그라디언트 레이어 추가
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
}
