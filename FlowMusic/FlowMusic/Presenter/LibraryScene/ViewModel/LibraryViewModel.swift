//
//  LibraryViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Combine
import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class LibraryViewModel: ViewModel {
    
    struct Input {
        let viewDidLoad: Observable<Void>
        let searchText: Observable<String>
        let likedSongTapped: Observable<Void>
        let recentlyPlayedSongTapped: Observable<Void>
        let itemSelected: Observable<MusicItem>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Void>
        let miniPlayerPreviousButtonTapped: ControlEvent<Void>
        let miniPlayerNextButtonTapped: ControlEvent<Void>
    }
    
    struct Output {
        let playlist: Driver<[(title: String, item: MusicItemCollection<Track>)]>
        let artists: Driver<MusicItemCollection<Artist>>
        let recentlyPlaylist: Driver<MusicItemCollection<Track>>
        let albums: Driver<MusicItemCollection<Album>>
        let currentPlaySong: Driver<Track?>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
        let searchResult: Driver<[Track]>
    }
    
    // MARK: - Properties
    
    weak var coordinator: LibraryCoordinator?
    let disposeBag = DisposeBag()
    private let musicPlayer = FMMusicPlayer()
    private let musicRepository = MusicRepository()
    private let playlistRepository = UserRepository<UserPlaylist>()
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private lazy var playStateSubject = BehaviorSubject<ApplicationMusicPlayer.PlaybackStatus>(value: musicPlayer.getPlaybackState())
    
    // MARK: - Lifecycles
    
    init(coordinator: LibraryCoordinator?) {
        self.coordinator = coordinator
        playerUpdateSink()
        playerStateUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        
        input
            .likedSongTapped
            .withUnretained(self)
            .subscribe{ owner, _ in
                let likeID = owner.fetchLikeList()
                Task {
                    do {
                        let result = try await self.musicRepository.requestLikeList(ids: likeID)
                        print(result)
//                        let playlist = MusicItem(result)
                        DispatchQueue.main.async {
                            owner.coordinator?.pushToList(track: result)
                        }
                    } catch {
                        print(error)
                    }
                }
        }.disposed(by: disposeBag)
        
//        input
//            .likedSongTapped
//            .withUnretained(self)
//            .subscribe{ owner, _ in
//                owner.coordinator?.pushToList(track: )
//        }.disposed(by: disposeBag)
        
        let searchResult = input.searchText
            .withUnretained(self)
            .flatMap { owner, text in
                owner.fetchSearchResult(text: text)
            }.asDriver(onErrorJustReturn: [])
            
//            .subscribe { owner, text in
//            print(text)
//            guard !text.isEmpty else { return }
//            Task {
//                let result = try await owner.musicRepository.requestSearchSongCatalog(term: text)
//                print(result)
//                let tracks = result.map { Track.song($0) }
//                owner.requestTrackSubject.onNext(tracks)
//            }
//        }.disposed(by: disposeBag)
        
        let playlist = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchPlaylist()
            }.asDriver(onErrorJustReturn: [])
        
        let artist = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchArtistList()
            }.asDriver(onErrorJustReturn: [])
        
//        let likes = input
//            .viewDidLoad
//            .withUnretained(self)
//            .flatMap { owner, _ in
//                owner.fetchLikeList()
//            }.asDriver(onErrorJustReturn: [])
        
        let recentlyPlaylist = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchRecentlyPlayList()
            }.asDriver(onErrorJustReturn: [])
        
        let albums = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchAlbumList()
            }.asDriver(onErrorJustReturn: [])
        
        input.itemSelected.withUnretained(self).subscribe { owner, item in
            //            owner.coordinator?.pushToList(item: item)
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
        
        return Output(playlist: playlist,
                      artists: artist,
                      recentlyPlaylist: recentlyPlaylist,
                      albums: albums,
                      currentPlaySong: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playStateSubject.asDriver(onErrorJustReturn: .playing),
                      searchResult: searchResult.asDriver(onErrorJustReturn: []))
    }
    
    private func fetchSearchResult(text: String) -> Observable<[Track]> {
        return Observable.create { [weak self] observer in
            guard let self,
                  !text.isEmpty
            else { return Disposables.create() }
            Task {
                let result = try await self.musicRepository.requestSearchSongCatalog(term: text)
                print(result)
                let tracks = result.map { Track.song($0) }
                observer.onNext(tracks)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    private func fetchPlaylist() -> Observable<[(title: String, item: MusicItemCollection<Track>)]> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let playlists = playlistRepository.fetchArr()
            Task {
                do {
                    var result = [(title: String, item: MusicItemCollection<Track>)]()
                    for list in playlists {
                        let title = list.title
                        let track = try await self.musicRepository.requestPlaylist(ids: Array(list.playlistID))
                        result.append((title: title, item: track))
                    }
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func fetchArtistList() -> Observable<MusicItemCollection<Artist>> {
        return Observable.create { [weak self] observer in
            guard let self,
                  let artist = artistRepository.fetchArr().first
            else { return Disposables.create() }
            Task {
                do {
                    let result = try await self.musicRepository.requestArtistList(ids: Array(artist.artistID))
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func fetchLikeList() -> [String] {
        guard let likes = likesRepository.fetchArr().first else { return [] }
        return Array(likes.likeID)
    }
    
    private func fetchRecentlyPlayList() -> Observable<MusicItemCollection<Track>> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            Task {
                do {
                    let result = try await self.musicRepository.requestRecentlyPlayed()
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func fetchAlbumList() -> Observable<MusicItemCollection<Album>> {
        return Observable.create { [weak self] observer in
            guard let self,
                  let albums = albumsRepository.fetchArr().first
            else { return Disposables.create() }
            Task {
                do {
                    let result = try await self.musicRepository.requestAlbumList(ids: Array(albums.albumID))
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
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

extension LibraryViewModel {
    //플레이어 상태 추적, 업데이트
    func playerUpdateSink() {
        musicPlayer.getCurrentPlayer().queue.objectWillChange.sink { _  in
            Task { [weak self] in
                guard let self,
                      let entry = try await musicPlayer.getCurrentEntry(),
                      let song = try await self.musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
                let track = Track.song(song)
                trackSubject.onNext(track)
            }
        }.store(in: &cancellables)
    }
    
    //음악 재생상태 추적, 업데이트
    func playerStateUpdateSink() {
        musicPlayer.getCurrentPlayer().state.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            let state = musicPlayer.getPlaybackState()
            playStateSubject.onNext(state)
        }.store(in: &cancellables)
    }
}
