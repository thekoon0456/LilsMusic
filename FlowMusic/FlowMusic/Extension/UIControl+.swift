//
//  UIControl+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/23/24.
//

import UIKit

extension UIControl {
    
    func tapImpact() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
    func tapAnimation() {
        addTarget(self, action: #selector(animateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }
    
    @objc private func animateDown() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        }
    }
    
    @objc private func animateUp() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            transform = .identity
        }
    }
    
    func progressAnimation() {
        addTarget(self, action: #selector(progressAnimateDown), for: .touchDown)
        addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchCancel, .touchDragExit])
    }
    
    @objc private func progressAnimateDown() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }
    }
}
