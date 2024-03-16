//
//  UserLibrary.swift
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

//유저가 좋아요 누른 아티스트
final class UserArtistList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var artistID: List<String>
    
    convenience init(title: String, artistID: List<String>) {
        self.init()
        self.artistID = artistID
    }
}

//유저가 좋아요 누른 곡들
final class UserLikeList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var likeID: List<String>
    
    convenience init(title: String, likeID: List<String>) {
        self.init()
        self.likeID = likeID
    }
}

//유저가 저장한 앨범 리스트
final class UserAlbumList: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var albumID: List<String>
    
    convenience init(title: String, albumID: List<String>) {
        self.init()
        self.albumID = albumID
    }
}
