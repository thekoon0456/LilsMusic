//
//  UINavigationController+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/25/24.
//

import UIKit

extension UINavigationController: UIGestureRecognizerDelegate {
    
    override open func viewDidLoad() {
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
