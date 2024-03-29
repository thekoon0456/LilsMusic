//
//  MusicListViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit
import StoreKit

import RxCocoa
import RxSwift

final class MusicListViewModel: ViewModel {
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<(index: Int, track: Track)>
        let playButtonTapped: Observable<Void>
        let shuffleButtonTapped: Observable<Void>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Bool>
        let miniPlayerPreviousButtonTapped: ControlEvent<Void>
        let miniPlayerNextButtonTapped: ControlEvent<Void>
        let popViewController: Observable<Void>
    }
    
    struct Output {
        let item: Driver<MusicItem?>
        let tracks: Driver<MusicItemCollection<Track>>
        let currentPlaySong: Driver<Track?>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicListCoordinator?
    private let musicPlayer = FMMusicPlayer.shared
    private let musicRepository = MusicRepository()
    private let musicItem = BehaviorSubject<MusicItem?>(value: nil)
    let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicListCoordinator?, item: MusicItem) {
        self.coordinator = coordinator
        musicItem.onNext(item)
    }
    
    // MARK: - Helpers
    
    func transform(_ input: Input) -> Output {
        
        let currentTrack = musicPlayer
            .currentEntrySubject
            .withUnretained(self)
            .flatMapLatest { owner, entry in
                owner.fetchCurrentTrackObservable(entry: entry)
            }
        
        let tracks = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.fetchTracksObservable()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Track>())
        
        input.playButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.tapImpact()
                Task {
                    guard let tracks = try await owner.fetchTracks(),
                          let firstItem = tracks.first else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex: 0)
                    owner.checkAppleMusicSubscriptionEligibility(track: firstItem)
                }
            }.disposed(by: disposeBag)
        
        input.shuffleButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.tapImpact()
                UserDefaultsManager.shared.userSetting.shuffleMode = .on
                owner.musicPlayer.setShuffleMode(mode: .on)
                Task {
                    guard let tracks = try await owner.fetchTracks(),
                          let firstItem = tracks.first else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex: 0)
                    owner.checkAppleMusicSubscriptionEligibility(track: firstItem)
                }
            }.disposed(by: disposeBag)
        
        input.itemSelected
            .withUnretained(self)
            .subscribe { owner, item in
                owner.tapImpact()
                owner.setQueue(index: item.index, track: item.track)
                owner.checkAppleMusicSubscriptionEligibility(track: item.track)
            }.disposed(by: disposeBag)
        
        input.miniPlayerTapped
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, track in
                guard let track else { return }
                owner.coordinator?.presentMusicPlayer(track: track)
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.miniPlayerPlayButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                let state = owner.musicPlayer.getPlaybackState()
                if state == .playing {
                    owner.musicPlayer.pause()
                } else {
                    Task {
                        try await owner.musicPlayer.play()
                    }
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.miniPlayerPreviousButtonTapped
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.miniPlayerNextButtonTapped
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.popViewController
            .withUnretained(self)
            .subscribe{ owner, _ in
                owner.coordinator?.popViewController()
                owner.coordinator?.finish()
            }.disposed(by: disposeBag)
        
        return Output(item: musicItem.asDriver(onErrorJustReturn: nil),
                      tracks: tracks,
                      currentPlaySong: currentTrack.asDriver(onErrorJustReturn: nil),
                      playState: musicPlayer.currentPlayStateSubject.asDriver(onErrorJustReturn: .playing))
    }
    
    func setQueue(index: Int, track: Track) {
        guard let musicItem = try? musicItem.value() else { return }
        Task { [weak self] in
            guard let self else { return }
            switch musicItem {
            case let playlist as Playlist:
                let playlist = try await playlist.with(.entries)
                guard let entry = playlist.entries?[index] else { return }
                try await musicPlayer.setPlaylistQueue(item: playlist, startEntry: entry)
            case let album as Album:
                try await musicPlayer.setAlbumQueue(item: album, startTrack: track)
            default:
                return
            }
        }
    }
    
    func fetchTracksObservable() -> Observable<MusicItemCollection<Track>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard let tracks = try await fetchTracks() else { return }
                    observer.onNext(tracks)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetchTracks() async throws -> MusicItemCollection<Track>? {
        guard let item = try? musicItem.value() else { return nil }
        switch item {
        case let playlist as Playlist:
            return try await musicRepository.playlistToTracks(playlist)
        case let album as Album:
            return try await musicRepository.albumToTracks(album)
        default:
            return nil
        }
    }
    
    func getCurrentPlaySong() -> Observable<Track?> {
        return Observable.create { observer in
            Task { [weak self] in
                do {
                    guard let self,
                          let entry = musicPlayer.getCurrentEntry(),
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
    
    func setPlayButton(isSelected: Bool) -> Observable<Bool> {
        return Observable.create { observer in
            observer.onNext(isSelected)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func fetchCurrentTrackObservable(entry: MusicPlayer.Queue.Entry?) -> Observable<Track?> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard let song = try await musicRepository.requestSearchSongIDCatalog(id: entry?.item?.id) else { return }
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

// MARK: - Apple뮤직 구독 유무 확인


extension MusicListViewModel {
    
    func checkAppleMusicSubscriptionEligibility(track: Track) {
        let controller = SKCloudServiceController()
        controller.requestCapabilities { [weak self] capabilities, error in
            guard let self else { return }
            if let error {
                print(error.localizedDescription)
                return
            }
            
            if capabilities.contains(.musicCatalogSubscriptionEligible) && !capabilities.contains(.musicCatalogPlayback) {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    coordinator?.presentAppleMusicSubscriptionOffer()
                }
                return
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    coordinator?.presentMusicPlayer(track: track)
                }
                return
            }
        }
    }
}
