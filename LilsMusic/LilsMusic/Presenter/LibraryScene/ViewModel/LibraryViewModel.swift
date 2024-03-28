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
        let viewWillAppear: Observable<Void>
        let playlistItemSelected: Observable<MusicItem>
        let likeItemSelected: Observable<(index: Int, track: Track)>
        let mixSelected: ControlEvent<Playlist>
        let miniPlayerTapped: Observable<Void>
        let miniPlayerPlayButtonTapped: Observable<Void>
        let miniPlayerPreviousButtonTapped: Observable<Void>
        let miniPlayerNextButtonTapped: Observable<Void>
    }
    
    struct Output {
        let mix: Driver<MusicItemCollection<Playlist>>
        let playlist: Driver<[(title: String, item: MusicItemCollection<Track>)]>
        let artists: Driver<MusicItemCollection<Artist>>
        let albums: Driver<MusicItemCollection<Album>>
        let likeTracks: Driver<MusicItemCollection<Track>>
        let currentPlaySong: Driver<Track?>
        let playState: Driver<ApplicationMusicPlayer.PlaybackStatus>
    }
    
    // MARK: - Properties
    
    weak var coordinator: LibraryCoordinator?
    let disposeBag = DisposeBag()
    private let musicPlayer = FMMusicPlayer.shared
    private let musicRepository = MusicRepository()
    private let playlistRepository = UserRepository<UserPlaylist>()
    private let artistRepository = UserRepository<UserArtistList>()
    private let likesRepository = UserRepository<UserLikeList>()
    private let albumsRepository = UserRepository<UserAlbumList>()
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private lazy var userLikeSubject = likesRepository.userLikeSubject
    
    // MARK: - Lifecycles
    
    init(coordinator: LibraryCoordinator?) {
        self.coordinator = coordinator
    }
    
    func transform(_ input: Input) -> Output {
        
        let currentEntry = musicPlayer
            .currentEntrySubject
            .withUnretained(self)
            .flatMapLatest { owner, entry in
                owner.fetchCurrentEntryTrackObservable(entry: entry)
            }
        
        let mix = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchRecommendMix()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let likeTracks = userLikeSubject
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchLikesList()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Track>())
        
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
        
        let albums = input
            .viewDidLoad
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchAlbumList()
            }.asDriver(onErrorJustReturn: [])
        
        input.mixSelected
            .withUnretained(self)
            .subscribe { owner, playlist in
                owner.coordinator?.pushToList(playlist: playlist)
            }.disposed(by: disposeBag)
        
        input.likeItemSelected
            .observe(on: MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe { owner, item in
                let likeID = owner.fetchLikeList()
                Task {
                    do {
                        let tracks = try await self.musicRepository.requestLikeList(ids: likeID)
                        try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex:item.index)
                        DispatchQueue.main.async {
                            owner.coordinator?.presentMusicPlayer(track: item.track)
                        }
                    } catch {
                        print(error)
                    }
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerTapped
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.getCurrentPlaySongObservable()
            }.asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, track in
                guard let track else { return }
                owner.coordinator?.presentMusicPlayer(track: track)
            }.disposed(by: disposeBag)
        
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
            }.disposed(by: disposeBag)
        
        input.miniPlayerPreviousButtonTapped
            .subscribe(with: self) { owner, _ in
                Task {
                        try await owner.musicPlayer.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.miniPlayerNextButtonTapped
            .subscribe(with: self) { owner, _ in
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                        try await owner.musicPlayer.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        return Output(mix: mix,
                      playlist: playlist,
                      artists: artist,
                      albums: albums,
                      likeTracks: likeTracks,
                      currentPlaySong: currentEntry.asDriver(onErrorJustReturn: nil),
                      playState: musicPlayer.currentPlayStateSubject.asDriver(onErrorJustReturn: .playing))
    }
    
    private func fetchLikesList() -> Observable<MusicItemCollection<Track>> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            let likeID = fetchLikeList()
            Task {
                do {
                    let result = try await self.musicRepository.requestLikeList(ids: likeID)
                    observer.onNext(result)
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
                    let playlist = try await musicRepository.requestCatalogMostPlayedCharts()
                    observer.onNext(playlist)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func fetchRecentlyPlayList() async throws -> MusicItemCollection<Track> {
        let result = try await self.musicRepository.requestRecentlyPlayed()
        return result
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
    
    func getCurrentPlaySongObservable() -> Observable<Track?> {
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
    
    func fetchCurrentEntryTrackObservable(entry: MusicPlayer.Queue.Entry?) -> Observable<Track?> {
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
    }}
//
//extension LibraryViewModel {
//    //플레이어 상태 추적, 업데이트
//    func playerUpdateSink() {
//        musicPlayer.getCurrentPlayer().queue.objectWillChange
//            .sink { _  in
//            Task { [weak self] in
//                guard let self,
//                      let entry = try await musicPlayer.getCurrentEntry(),
//                      let song = try await self.musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
//                let track = Track.song(song)
//                trackSubject.onNext(track)
//            }
//        }.store(in: &cancellables)
//    }
//    
//    //음악 재생상태 추적, 업데이트
//    func playerStateUpdateSink() {
//        musicPlayer.getCurrentPlayer().state.objectWillChange
//            .sink { [weak self] _ in
//            guard let self else { return }
//            let state = musicPlayer.getPlaybackState()
//            playStateSubject.onNext(state)
//        }.store(in: &cancellables)
//    }
//}
