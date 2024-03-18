//
//  MusicRecommendViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

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
        let miniPlayerPlayState:  Driver<Bool>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicPlayer = FMMusicPlayer()
    private let musicRepository = MusicRepository()
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
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
        
        let currentPlaySong = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, void in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
        
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
        
        let miniPlayerPlayState = input.miniPlayerPlayButtonTapped
            .withUnretained(self)
            .do { owner, _ in
                Task {
                    switch owner.musicPlayer.getPlaybackState() {
                    case .playing:
                        owner.musicPlayer.pause()
                    default:
                        try await owner.musicPlayer.play()
                    }
                }
            }
            .map { owner, _ in
                return owner.musicPlayer.getPlaybackState() == .playing ? true : false
            }
            .withUnretained(self)
            .flatMap { owner, bool in
                owner.setPlayButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: false)
        
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
        
        return Output(currentPlaySong: currentPlaySong,
                      recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums,
                      recommendMixList: mix,
                      miniPlayerPlayState: miniPlayerPlayState)
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
    
    func getPlayerState() -> Observable<ApplicationMusicPlayer.PlaybackStatus> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let entry = musicPlayer.getPlaybackState()
            observer.onNext(entry)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
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
