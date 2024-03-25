//
//  Array+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/13/24.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
