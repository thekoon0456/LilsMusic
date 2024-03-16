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
        
        var name: String {
            switch self {
            case .recommend:
                "music.note.tv"
            case .reels:
                "play.rectangle.on.rectangle"
            case .library:
                "list.bullet.rectangle.portrait"
            case .user:
                "music.note.house"
            }
        }
        
        var fill: String {
            switch self {
            case .recommend:
                "music.note.tv.fill"
            case .reels:
                "play.rectangle.on.rectangle.fill"
            case .library:
                "list.bullet.rectangle.portrait.fill"
            case .user:
                "music.note.house.fill"
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
