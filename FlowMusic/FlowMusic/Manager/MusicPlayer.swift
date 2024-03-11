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
    let player = ApplicationMusicPlayer.shared
    
    // MARK: - Lifecycles
    
    private init() { }
    
    // MARK: - Helpers
    
    // MARK: - Queue
    
    func insertTrackAfterCurrentEntry(track: Track) async throws {
        try await player.queue.insert(track, position: .afterCurrentEntry)
    }
    
    func insertTrackToTail(track: Track) async throws {
        // 플레이어의 큐에 설정
        try await player.queue.insert(track, position: .tail)
    }
    
    func insertItemsAfterCurrentEntry(songs: MusicItemCollection<Song>) async throws {
        try await player.queue.insert(songs, position: .afterCurrentEntry)
    }
    
    func insertItemsToTail(songs: MusicItemCollection<Song>) async throws {
        // 플레이어의 큐에 설정
        try await player.queue.insert(songs, position: .tail)
    }
    
    func getCurrentEntry() -> ApplicationMusicPlayer.Queue.Entry? {
        // MARK: - entry가 한칸씩 밀려서 + 1해서 싱크 맞춤
        // 플레이어의 큐에 설정
        guard let entry = player.queue.currentEntry,
              let index = player.queue.entries.firstIndex(of: entry)
        else { return nil }
        return player.queue.entries[index + 1]
    }
    
    func setAlbumQueue(album: Album, track: Track) {
        player.queue = ApplicationMusicPlayer.Queue(album: album, startingAt: track)
    }
    
    func setSongQueue(song: Song) {
        player.queue = [song]
    }
    
    func resetQueue() {
        player.queue = []
    }
    
    // MARK: - Play
    
    func play() async throws {
        try await player.prepareToPlay()
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
