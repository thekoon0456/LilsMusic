//
//  MusicPlayer.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit

final class  MusicPlayer {
    
    // MARK: - Properties
    
    static let shared = MusicPlayer()
    private let player = ApplicationMusicPlayer.shared
    
    // MARK: - Lifecycles
    
    private init() { }
    
    // MARK: - Helpers
    
    // MARK: - Queue
    
    func insertItemAfterCurrentEntry(song: Song) async throws {
        try await player.queue.insert(song, position: .afterCurrentEntry)
    }
    
    func insertItemToTail(song: Song) async throws {
        // 플레이어의 큐에 설정
        try await player.queue.insert(song, position: .tail)
    }
    
    func insertItemsAfterCurrentEntry(songs: MusicItemCollection<Song>) async throws {
        try await player.queue.insert(songs, position: .afterCurrentEntry)
    }
    
    func insertItemsToTail(songs: MusicItemCollection<Song>) async throws {
        // 플레이어의 큐에 설정
        try await player.queue.insert(songs, position: .tail)
    }
    
    func getCurrentEntry() -> ApplicationMusicPlayer.Queue.Entry? {
        // 플레이어의 큐에 설정
        return player.queue.currentEntry
    }
    
    // MARK: - Play
    
    func play() async throws {
        try await player.play()
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
    
    //한곡 추가
    func playSong(_ song: Song) async throws {
        player.queue = [song]
        try await player.play()
    }
    
    func getPlayBackTime() -> TimeInterval {
        player.playbackTime
    }
    
    func isPreparedToPlay() -> Bool {
        player.isPreparedToPlay
    }
}
