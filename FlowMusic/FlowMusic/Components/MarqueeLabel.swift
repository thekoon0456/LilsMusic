//
//  MarqueeLabel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

final class MarqueeLabel: UILabel {
    // 애니메이션 지속 시간
    var animationDuration: TimeInterval = 7.0
    // 애니메이션 대기 시간
    var pauseDuration: TimeInterval = 1.5
    
    func startMarqueeAnimation() {
        guard let superview = superview else { return }

        // 텍스트 너비 계산
        let textSize = text?.size(withAttributes: [.font: font!]) ?? .zero
        let labelWidth = frame.size.width
        
        // 텍스트가 UILabel 너비를 초과하는 경우에만 애니메이션 실행
        guard textSize.width > labelWidth else { return }

        // 애니메이션 시작 전 초기 상태 설정
        self.transform = .identity
        self.layer.removeAllAnimations()

        UIView.animateKeyframes(withDuration: animationDuration, delay: pauseDuration, options: [.repeat, .autoreverse], animations: {
            // 텍스트가 왼쪽으로 이동하여 끝까지 보이게 함
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0) {
                self.transform = CGAffineTransform(translationX: -(textSize.width - labelWidth), y: 0)
            }
        })
    }
}
