//
//  UserSetting.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/16/24.
//

import Foundation

struct UserSetting: Codable {
    static let key: String = "UserSetting"
    var shuffleMode: ShuffleMode
    var repeatMode: RepeatMode
}

enum ShuffleMode: Codable {
    case off
    case on
    
    mutating func toggle() {
        switch self {
        case .off:
            self = .on
        case .on:
            self = .off
        }
    }
}

enum RepeatMode: Codable {
    case all
    case one
    case off
    
    mutating func toggle() {
        switch self {
        case .all:
            self = .one
        case .one:
            self = .off
        case .off:
            self = .all
        }
    }
    
    var iconName: String {
        switch self {
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        case .off:
            return "autostartstop.slash"
        }
    }
}
