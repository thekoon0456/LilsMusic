//
//  LibraryListViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/22/24.
//

import Combine
import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class LibraryListViewModel: ViewModel {
    
    struct Input {
        let itemSelected: Observable<(index: Int, track: Track)>
        let playButtonTapped: Observable<Void>
        let shuffleButtonTapped: Observable<Void>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Bool>
        let miniPlayerPreviousButtonTapped: ControlEvent<Void>
        let miniPlayerNextButtonTapped: ControlEvent<Void>
    }
    
    struct Output {
        let item: Driver<MusicItem?>
        let tracks: Driver<MusicItemCollection<Track>>
        let currentPlaySong: Driver<Track?>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: LibraryListCoordinator?
    private let musicPlayer = FMMusicPlayer()
    private let musicRepository = MusicRepository()
    private let musicItem = BehaviorSubject<MusicItem?>(value: nil)
    let disposeBag = DisposeBag()
    private var cancellable = Set<AnyCancellable>()
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private let trackListSubject = BehaviorSubject<MusicItemCollection<Track>>(value: [])
    private lazy var playStateSubject = BehaviorSubject<ApplicationMusicPlayer.PlaybackStatus>(value: musicPlayer.getPlaybackState())
    
    // MARK: - Lifecycles
    
    init(coordinator: LibraryListCoordinator?, tracks: MusicItemCollection<Track>) {
        self.coordinator = coordinator
        trackListSubject.onNext(tracks)
        musicItem.onNext(tracks.first)
        playerUpdateSink()
        playerStateUpdateSink()
    }
    
    // MARK: - Helpers
    
    
    func transform(_ input: Input) -> Output {

        input.playButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    guard let tracks = try? owner.trackListSubject.value(),
                          let firstItem = tracks.first else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex: 0)
                    DispatchQueue.main.async {
                        owner.coordinator?.presentMusicPlayer(track: firstItem)
                    }
                }
            }.disposed(by: disposeBag)
        
        input.shuffleButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    guard let tracks = try? owner.trackListSubject.value(),
                          let firstItem = tracks.first else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex: 0)
                    UserDefaultsManager.shared.userSetting.shuffleMode = .on
                    owner.musicPlayer.setShuffleMode(mode: .on)
                    DispatchQueue.main.async {
                        owner.coordinator?.presentMusicPlayer(track: firstItem)
                    }
                }

            }.disposed(by: disposeBag)
        
        input.itemSelected
            .withUnretained(self)
            .subscribe { owner, item in
                Task {
                    guard let tracks = try? owner.trackListSubject.value() else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex:item.index)
                    DispatchQueue.main.async {
                        owner.coordinator?.presentMusicPlayer(track: item.track)
                    }
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerTapped
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, track in
                guard let track else { return }
                owner.coordinator?.presentMusicPlayer(track: track)
            }.disposed(by: disposeBag)
        
        input.miniPlayerPlayButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                let state = owner.musicPlayer.getPlaybackState()
                if state == .playing {
                    owner.musicPlayer.setPaused()
                } else {
                    Task {
                        try await owner.musicPlayer.setPlaying()
                    }
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerPreviousButtonTapped
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerNextButtonTapped
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        return Output(item: musicItem.asDriver(onErrorJustReturn: nil),
                      tracks: trackListSubject.asDriver(onErrorJustReturn: []),
                      currentPlaySong: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playStateSubject.asDriver(onErrorJustReturn: .playing))
    }
    
    func getCurrentPlaySong() -> Observable<Track?> {
        return Observable.create { observer in
            Task { [weak self] in
                do {
                    guard let self,
                          let entry = try await musicPlayer.getCurrentEntry(),
                          let song = try await self.musicRepository.requestSearchSongIDCatalog(id: entry.item?.id)
                    else { return }
                    let track = Track.song(song)
                    observer.onNext(track)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - 플레이어 상태 추적, 업데이트

extension LibraryListViewModel {
    
    func playerUpdateSink() {
        musicPlayer.getCurrentPlayer().queue.objectWillChange.sink { _  in
            Task { [weak self] in
                guard let self,
                      let entry = try await musicPlayer.getCurrentEntry(),
                      let song = try await self.musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
                let track = Track.song(song)
                trackSubject.onNext(track)
            }
        }.store(in: &cancellable)
    }
    
    //음악 재생상태 추적, 업데이트
    func playerStateUpdateSink() {
        musicPlayer.getCurrentPlayer().state.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            let state = musicPlayer.getPlaybackState()
            playStateSubject.onNext(state)
        }.store(in: &cancellable)
    }
}
