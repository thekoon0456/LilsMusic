//
//  String+.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation

extension String {
    
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with: String) -> String {
        return String(format: self.localized, with) //%@
    }
    
    func localized(number: Int) -> String {
        return String(format: self.localized, number) //%lld
    }
}
