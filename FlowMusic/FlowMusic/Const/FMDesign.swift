//
//  FMDesign.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

enum FMDesign {
    
    enum Icon {
        case recommend
        case reels
        case library
        case user
        case chevronDown
        case plus
        case heart
        
        var name: String {
            switch self {
            case .recommend:
                "music.note.house"
            case .reels:
                "play.square.stack"
            case .library:
                "list.bullet.rectangle.portrait"
            case .user:
                "music.note.house"
            case .chevronDown:
                "chevron.compact.down"
            case .plus:
                "plus.circle"
            case .heart:
                "heart"
            }
        }
        
        var fill: String {
            switch self {
            case .recommend:
                "music.note.house.fill"
            case .reels:
                "play.square.stack.fill"
            case .library:
                "list.bullet.rectangle.portrait.fill"
            case .user:
                "music.note.house.fill"
            case .chevronDown:
                ""
            case .plus:
                ""
            case .heart:
                "heart.fill"
            }
        }
    }
    
    enum Color {
        case tintColor
        
        var color: UIColor {
            switch self {
            case .tintColor:
                    .systemGreen
            }
        }
    }
    
}
