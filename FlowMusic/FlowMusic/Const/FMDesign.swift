//
//  FMDesign.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation

enum FMDesign {
    
    enum Icon {
        case recommend
        case reels
        case playlist
        case user
        
        var name: String {
            switch self {
            case .recommend:
                "music.note.tv"
            case .reels:
                "play.rectangle.on.rectangle"
            case .playlist:
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
            case .playlist:
                "list.bullet.rectangle.portrait.fill"
            case .user:
                "music.note.house.fill"
            }
        }
    }
}
