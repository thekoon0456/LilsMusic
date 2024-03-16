//
//  Music.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/11/24.
//

import Foundation

import RealmSwift

//유저가 추가하는 플레이리스트
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

//유저가 좋아요 누른 곡들
final class likeList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var likeID: List<String>
    
    convenience init(title: String, likeID: List<String>) {
        self.init()
        self.likeID = likeID
    }
}

//유저가 좋아요 누른 아티스트
final class artistList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var artistID: List<String>
    
    convenience init(title: String, artistID: List<String>) {
        self.init()
        self.artistID = artistID
    }
}

//유저가 좋아요 누른 Station
final class stationList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var stationID: List<String>
    
    convenience init(title: String, stationID: List<String>) {
        self.init()
        self.stationID = stationID
    }
}
