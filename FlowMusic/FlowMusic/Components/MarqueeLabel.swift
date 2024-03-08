//
//  MarqueeLabel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

final class MarqueeLabel: UILabel {
    
    var marqueeText: String? {
           didSet {
               self.text = marqueeText
               configureMarqueeAnimation()
           }
       }
    
    // 애니메이션 지속 시간
    var animationDuration: TimeInterval = 7.0
    // 애니메이션 대기 시간
    var pauseDuration: TimeInterval = 1.5
    
    private func configureMarqueeAnimation() {
        guard let text = self.text, let font = self.font else { return }
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        
        // 텍스트 길이가 라벨 너비를 초과하는 경우에만 애니메이션 실행
        guard textSize.width > self.bounds.width else { return }

        // 애니메이션 시작 전 초기 상태 설정
        self.layer.removeAllAnimations()
        self.transform = .identity

        // 애니메이션 실행
        UIView.animate(withDuration: animationDuration, delay: pauseDuration, options: [.curveLinear], animations: {
            // 첫 번째 단계: 오른쪽 끝까지 이동
            self.transform = CGAffineTransform(translationX: -(textSize.width - self.bounds.width), y: 0)
        }) { _ in
            // 두 번째 단계: 원래 위치로 되돌리기
            UIView.animate(withDuration: self.animationDuration, delay: self.pauseDuration, options: [.curveLinear], animations: {
                self.transform = .identity
            })
        }
    }
}
