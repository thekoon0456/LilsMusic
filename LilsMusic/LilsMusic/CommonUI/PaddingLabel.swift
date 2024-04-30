//
//  PaddingLabel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/12/24.
//

import UIKit

final class PaddingLabel: UILabel {
    
    var padding = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right

        return contentSize
    }
}
