//
//  Music.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/11/24.
//

import Foundation

import RealmSwift

final class UserPlaylist: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var title: String
    @Persisted var playlistID: List<String>
    
    convenience init(title: String, playlistID: List<String>) {
        self.init()
        self.title = title
        self.playlistID = playlistID
    }
}
