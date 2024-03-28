//
//  MusicPlayer.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit

final class FMMusicPlayer {
    
    // MARK: - Properties
    static let shared = FMMusicPlayer()
    
    private let player = ApplicationMusicPlayer.shared
    private let userDefaultsManager = UserDefaultsManager.shared
    
    private init() {
        setRepeatMode(mode: userDefaultsManager.userSetting.repeatMode)
    }
    
    // MARK: - Lifecycles
    
    func getCurrentEntry() async throws -> ApplicationMusicPlayer.Queue.Entry? {
        try await Task.sleep(nanoseconds: 200_000_000)
        return player.queue.currentEntry
    }
    
    // MARK: - Set Queue
    
    func getQueue() -> ApplicationMusicPlayer.Queue.Entries {
        player.queue.entries
    }
    
    func setSongQueue(item: MusicItemCollection<Song>, startIndex: Int) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: item, startingAt: item[startIndex])
        player.queue = queue
        try await play()
    }
    
    func setTrackQueue(item: MusicItemCollection<Track>, startIndex: Int) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: item, startingAt: item[startIndex])
        player.queue = queue
        try await play()
    }
    
    func setAlbumQueue(item: MusicItemCollection<Album>, startIndex: Int) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: item, startingAt: item[startIndex])
        player.queue = queue
        try await play()
    }
    
    func setPlaylistQueue(item: MusicItemCollection<Playlist>, startIndex: Int) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: item, startingAt: item[startIndex])
        player.queue = queue
        try await play()
    }
    
    func setStationQueue(item: MusicItemCollection<Station>, startIndex: Int) async throws {
        let queue = ApplicationMusicPlayer.Queue(for: item, startingAt: item[startIndex])
        player.queue = queue
        try await play()
    }
    
    //한곡 재생
    func playSong(_ song: Song) async throws {
        player.queue = [song]
        try await play()
    }
    
    func playTrack(_ track: Track) async throws {
        player.queue = [track]
        try await play()
    }
    
    func resetQueue() {
        player.queue = []
    }
    
    // MARK: - Play
    
    func play() async throws {
        Task {
            do {
                try await player.prepareToPlay()
                try await player.play()
            } catch {
                print("playError: ", error.localizedDescription)
                try await player.play()
            }
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    func restart() {
        player.restartCurrentEntry()
    }
    
    func skipToNext() async throws {
        try await player.skipToNextEntry()
    }
    
    func skipToPrevious() async throws  {
        try await player.skipToPreviousEntry()
    }
    
    func setRepeatMode(mode: RepeatMode) {
        switch mode {
        case .all:
            player.state.repeatMode = .all
        case .one:
            player.state.repeatMode = .one
        case .off:
            player.state.repeatMode = .none
        }
    }
    
    func setShuffleMode(mode: ShuffleMode) {
        switch mode {
        case .on:
            player.state.shuffleMode = .songs
        case .off:
            player.state.shuffleMode = .off
        }
    }

    // MARK: - Player Status
    
    //현재 플레이타임
    func getPlayBackTime() -> TimeInterval {
        player.playbackTime
    }
    
    func setPlayBackTime(value: Double) {
        player.playbackTime = TimeInterval(floatLiteral: value)
    }
    
    //현재 재생 여부
    func getPlaybackState() -> ApplicationMusicPlayer.PlaybackStatus {
          player.state.playbackStatus
    }
    
    //현재 재생 여부
    func setPaused() {
        player.pause()
//        switch state {
//        case .stopped:
//            <#code#>
//        case .playing:
//            <#code#>
//        case .paused:
//            <#code#>
//        case .interrupted:
//            <#code#>
//        case .seekingForward:
//            <#code#>
//        case .seekingBackward:
//            <#code#>
//        }
    }
    
    //현재 재생 여부
    func setPlaying() async throws {
        Task {
            try await player.play()
        }
    }
     
    //재생준비 상태
    func isPreparedToPlay() -> Bool {
        player.isPreparedToPlay
    }
    
    func getCurrentPlayer() -> ApplicationMusicPlayer {
        player
    }
}

// MARK: - Queue
//
//    func setSongQueue(item: Song, startIndex: Int) async throws {
//        let entry = ApplicationMusicPlayer.Queue.Entry(item)
//        player.queue.entries.insert(entry, at: startIndex)
//        try await play()
//    }
//
//    func setAlbumQueue(item: Album, startIndex: Int) async throws {
//        let entry = ApplicationMusicPlayer.Queue.Entry(item)
//        player.queue.entries.insert(entry, at: startIndex)
//        try await play()
//    }
//
//    func setPlaylistQueue(item: Playlist, startIndex: Int) async throws {
//        let entry = ApplicationMusicPlayer.Queue.Entry(item)
//        player.queue.entries.insert(entry, at: startIndex)
//        try await play()
//    }
//
//    //현재 재생 다음에 큐 설정
//    func insertSongsAfterCurrentEntry(songs: MusicItemCollection<Song>) async throws {
//        try await player.queue.insert(songs, position: .afterCurrentEntry)
//    }
//
//    //큐 가장 마지막에 설정
//    func insertSongsToTail(songs: MusicItemCollection<Song>) async throws {
//        try await player.queue.insert(songs, position: .tail)
//    }
