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
        let recommendMixList: Driver<MusicItemCollection<Playlist>>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicPlayer = FMMusicPlayer.shared
    private let musicRepository = MusicRepository()
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
//        playerUpdateSink()
//        playerStateUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        
        let currentEntry = musicPlayer
            .currentEntrySubject
            .withUnretained(self)
            .flatMap { owner, entry in
                owner.fetchCurrentEntry(entry: entry)
            }
        
        let state = musicPlayer
            .currentPlayStateSubject
        
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
        
        input.searchModelSelected
            .withUnretained(self)
            .subscribe { owner, track in
                Task {
                        try await owner.musicPlayer.playTrack(track)
                    }
                DispatchQueue.main.async {
                    owner.coordinator?.presentMusicPlayer(track: track)
                }
            }.disposed(by: disposeBag)
        
        let searchResult = input.searchText
            .withUnretained(self)
            .flatMap { owner, text in
                owner.fetchSearchResult(text: text)
            }.asDriver(onErrorJustReturn: [])
        
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
                    owner.musicPlayer.pause()
                } else {
                    Task {
                        try await owner.musicPlayer.play()
                    }
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerPreviousButtonTapped
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                        try await owner.musicPlayer.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerNextButtonTapped
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                        try await owner.musicPlayer.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        return Output(searchResult: searchResult.asDriver(onErrorJustReturn: []),
                      currentPlaySong: currentEntry.asDriver(onErrorJustReturn: nil),
                      recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums,
                      recommendMixList: mix,
                      playState: state.asDriver(onErrorJustReturn: .playing))
    }
    
    
    private func fetchSearchResult(text: String) -> Observable<[Track]> {
        return Observable.create { [weak self] observer in
            guard let self,
                  !text.isEmpty
            else { return Disposables.create() }
            Task {
                let result = try await self.musicRepository.requestSearchSongCatalog(term: text)
                let tracks = result.map { Track.song($0) }
                observer.onNext(tracks)
                observer.onCompleted()
            }
            return Disposables.create()
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
    
    func fetchRecommendSongs() -> Observable<MusicItemCollection<Playlist>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let songs = try await musicRepository.requestCatalogTop100Charts()
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
    
    func fetchCurrentEntry(entry: MusicPlayer.Queue.Entry?) -> Observable<Track?> {
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
