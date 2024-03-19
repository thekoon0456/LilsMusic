//
//  MusicRecommendViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Combine
import Foundation
import MusicKit

import RxCocoa

import RxSwift

final class MusicRecommendViewModel: ViewModel {
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<MusicItem>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Void>
        let miniPlayerPreviousButtonTapped: ControlEvent<Void>
        let miniPlayerNextButtonTapped: ControlEvent<Void>
    }
    
    struct Output {
        let currentPlaySong: Driver<Track?>
        let recommendSongs: Driver<MusicItemCollection<Playlist>>
        let recommendPlaylists: Driver<MusicItemCollection<Playlist>>
        let recommendAlbums: Driver<MusicItemCollection<Album>>
        let recommendMixList: Driver<MusicItemCollection<Playlist>>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicPlayer = FMMusicPlayer()
    private let musicRepository = MusicRepository()
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    let disposeBag = DisposeBag()
    private var cancellable = Set<AnyCancellable>()
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private lazy var playStateSubject = BehaviorSubject<ApplicationMusicPlayer.PlaybackStatus>(value: musicPlayer.getPlaybackState())
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
        playerUpdateSink()
        playerStateUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        
        //realm 없으면 처음에 한번 생성
        input
            .viewDidLoad
            .withUnretained(self)
            .subscribe{ owner, _ in
                if owner.artistRepository.fetch().isEmpty {
                    owner.artistRepository.createItem(UserArtistList())
                }
                if owner.likesRepository.fetch().isEmpty {
                    owner.likesRepository.createItem(UserLikeList())
                }
                if owner.albumsRepository.fetch().isEmpty {
                    owner.albumsRepository.createItem(UserAlbumList())
                }
                print(owner.likesRepository.printURL())
            }.disposed(by: disposeBag)
        
        let songs = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendSongs()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let playlists = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendPlaylists()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let albums = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendAlbums()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Album>())
        
        let mix = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendMix()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        input.itemSelected.withUnretained(self).subscribe { owner, item in
            DispatchQueue.main.async {
                owner.coordinator?.pushToList(item: item)
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
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        return Output(currentPlaySong: trackSubject.asDriver(onErrorJustReturn: nil),
                      recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums,
                      recommendMixList: mix,
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
    
//    func getPlayerState() -> Observable<ApplicationMusicPlayer.PlaybackStatus> {
//        return Observable.create { [weak self] observer in
//            guard let self else { return Disposables.create() }
//            let entry = musicPlayer.getPlaybackState()
//            observer.onNext(entry)
//            observer.onCompleted()
//            return Disposables.create()
//        }
//    }
    
    func fetchRecommendSongs() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let songs = try await musicRepository.requestCatalogTop100Charts()
                    print(songs)
                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchRecommendPlaylists() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let playlists = try await musicRepository.requestCatalogPlaylistCharts()
                    observer.onNext(playlists)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchRecommendAlbums() -> Observable<MusicItemCollection<Album>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let albums = try await musicRepository.requestCatalogAlbumCharts()
                    observer.onNext(albums)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchRecommendMix() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let stations = try await musicRepository.requestCatalogMostPlayedCharts()
                    print(stations)
                    observer.onNext(stations)
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
}

// MARK: - 플레이어 상태 추적, 업데이트

extension MusicRecommendViewModel {
    
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
