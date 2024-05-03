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
        let searchText: Observable<String>
        let searchModelSelected: ControlEvent<Track>
        let itemSelected: Observable<MusicItem>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Void>
        let miniPlayerPreviousButtonTapped: ControlEvent<Void>
        let miniPlayerNextButtonTapped: ControlEvent<Void>
    }
    
    struct Output {
        let searchResult: Driver<[Track]>
        let currentPlaySong: Driver<Track?>
        let recommendSongs: Driver<MusicItemCollection<Playlist>>
        let recommendPlaylists: Driver<MusicItemCollection<Playlist>>
        let recommendAlbums: Driver<MusicItemCollection<Album>>
        let cityTop25: Driver<MusicItemCollection<Playlist>>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicPlayer = FMMusicPlayer.shared
    private let musicAPIManager = MusicAPIManager.shared
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
    }
    
    func transform(_ input: Input) -> Output {
        
        let currentEntry = musicPlayer
            .currentEntrySubject
            .withUnretained(self)
            .flatMapLatest { owner, entry in
                owner.fetchCurrentEntryTrackObservable(entry: entry)
            }
        
        let playState = musicPlayer
            .currentPlayStateSubject
        
        //realm 없으면 처음에 한번 생성
        input
            .viewDidLoad
            .subscribe(with: self) { owner, _ in
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
            }
            .disposed(by: disposeBag)
        
        input.searchModelSelected
            .subscribe(with: self) { owner, track in
                Task {
                    try await owner.musicPlayer.playTrack(track)
                }
                DispatchQueue.main.async {
                    owner.coordinator?.presentMusicPlayer(track: track)
                }
            }
            .disposed(by: disposeBag)
        
        let searchResult = input.searchText
            .withUnretained(self)
            .flatMapLatest { owner, text in
                owner.fetchSearchResultObservable(text: text)
            }
            .asDriver(onErrorJustReturn: [])
        
        let songs = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendSongsObservable()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let playlists = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendPlaylistsObservable()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let albums = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendAlbumsObservable()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Album>())
        
        let cityTop25 = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchCityTopObservable()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        input.itemSelected
            .subscribe(with: self) { owner, item in
                DispatchQueue.main.async {
                    owner.coordinator?.pushToList(item: item)
                }
            }
            .disposed(by: disposeBag)
        
        input.miniPlayerTapped
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.getCurrentPlaySongObservable()
            }.asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, track in
                guard let track else { return }
                owner.coordinator?.presentMusicPlayer(track: track)
            }
            .disposed(by: disposeBag)
        
        input.miniPlayerPlayButtonTapped
            .subscribe(with: self) { owner, _ in
                let state = owner.musicPlayer.getPlaybackState()
                if state == .playing {
                    owner.musicPlayer.pause()
                } else {
                    Task {
                        try await owner.musicPlayer.play()
                    }
                }
            }
            .disposed(by: disposeBag)
        
        input.miniPlayerPreviousButtonTapped
            .subscribe(with: self) { owner, _ in
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
            }
            .disposed(by: disposeBag)
        
        input.miniPlayerNextButtonTapped
            .subscribe(with: self) { owner, _ in
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
            }
            .disposed(by: disposeBag)
        
        return Output(searchResult: searchResult.asDriver(onErrorJustReturn: []),
                      currentPlaySong: currentEntry.asDriver(onErrorJustReturn: nil),
                      recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums,
                      cityTop25: cityTop25,
                      playState: playState.asDriver(onErrorJustReturn: .playing))
    }
    
    
    private func fetchSearchResultObservable(text: String) -> Observable<[Track]> {
        return Observable.create { [weak self] observer in
            guard let self,
                  !text.isEmpty
            else { return Disposables.create() }
            Task {
                let result = try await self.musicAPIManager.requestSearchSongCatalog(term: text)
                let tracks = result.map { Track.song($0) }
                observer.onNext(tracks)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    func getCurrentPlaySongObservable() -> Observable<Track?> {
        return Observable.create { observer in
            Task { [weak self] in
                do {
                    guard let self,
                          let entry = musicPlayer.getCurrentEntry(),
                          let song = try await self.musicAPIManager.requestSearchSongIDCatalog(id: entry.item?.id)
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
    
    func fetchRecommendSongsObservable() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let songs = try await musicAPIManager.requestCatalogTop100Charts()
                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchRecommendPlaylistsObservable() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let playlists = try await musicAPIManager.requestCatalogPlaylistCharts()
                    observer.onNext(playlists)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchRecommendAlbumsObservable() -> Observable<MusicItemCollection<Album>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let albums = try await musicAPIManager.requestCatalogAlbumCharts()
                    observer.onNext(albums)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchCityTopObservable() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let stations = try await musicAPIManager.requestCatalogCityTop25Charts()
                    observer.onNext(stations)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    func setPlayButtonObservable(isSelected: Bool) -> Observable<Bool> {
        return Observable.create { observer in
            observer.onNext(isSelected)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func fetchCurrentEntryTrackObservable(entry: MusicPlayer.Queue.Entry?) -> Observable<Track?> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    guard let song = try await musicAPIManager.requestSearchSongIDCatalog(id: entry?.item?.id) else { return }
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
