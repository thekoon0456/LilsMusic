//
//  UserSetting.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/16/24.
//

import Foundation

struct UserSetting: Codable {
    static let key: String = "UserSetting"
    var isShuffled: Bool
    var repeatMode: RepeatMode
}

enum RepeatMode: Codable {
    case all
    case one
    case none
    
    mutating func toggle() {
        switch self {
        case .all:
            self = .one
        case .one:
            self = .none
        case .none:
            self = .all
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        case .none:
            return "autostartstop.slash"
        }
    }
}
