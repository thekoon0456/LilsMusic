//
//  MusicPlayer.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Combine
import Foundation
import MusicKit

import RxSwift

final class FMMusicPlayer {
    
    // MARK: - Properties
    static let shared = FMMusicPlayer()
    
    private let player = ApplicationMusicPlayer.shared
    private let userDefaultsManager = UserDefaultsManager.shared
    
    let currentEntrySubject = BehaviorSubject<MusicPlayer.Queue.Entry?>(value: nil)
    lazy var currentPlayStateSubject = BehaviorSubject<MusicPlayer.PlaybackStatus>(value: getPlaybackState())
    private var cancellable = Set<AnyCancellable>()
    
    private init() {
        setCurrentEntrySubject()
        setPlayStateSubject()
        setRepeatMode(mode: userDefaultsManager.userSetting.repeatMode)
    }
    
    // MARK: - Lifecycles
    
    func getCurrentEntry() -> ApplicationMusicPlayer.Queue.Entry? {
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
    
    func setCurrentEntrySubject() {
        player.queue.objectWillChange
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] _  in
                guard let self else { return }
                let entry = player.queue.currentEntry
                currentEntrySubject.onNext(entry)
        }.store(in: &cancellable)
    }
    
    //음악 재생상태 추적, 업데이트
    func setPlayStateSubject() {
        player.state.objectWillChange
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
            guard let self else { return }
            let state = getPlaybackState()
            currentPlayStateSubject.onNext(state)
        }.store(in: &cancellable)
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
