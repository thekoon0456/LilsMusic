//
//  MarqueeLabel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/19/24.
//

import UIKit

class MarqueeLabel: UILabel {
    
    func startMarqueeAnimation(duration: Double) {
        guard let superview = superview else { return }

        // 라벨의 초기 위치를 설정
        self.frame.origin.x = superview.bounds.width

        // 애니메이션을 사용하여 라벨을 왼쪽으로 이동
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .curveLinear], animations: {
            // 라벨을 왼쪽으로 이동시켜서 스크롤 효과를 만듦
            self.frame.origin.x = -self.bounds.width
        }, completion: nil)
    }
}
