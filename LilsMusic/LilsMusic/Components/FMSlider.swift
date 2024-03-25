//
//  FMSlider.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import UIKit

final class FMSlider: UISlider {
    
    private var barHeight: CGFloat = 0
    
    convenience init(barHeight: CGFloat) {
        self.init()
        self.barHeight = barHeight
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func trackRect(forBounds bound: CGRect) -> CGRect {
        CGRectMake(0, 0, frame.width, barHeight)
    }
}
