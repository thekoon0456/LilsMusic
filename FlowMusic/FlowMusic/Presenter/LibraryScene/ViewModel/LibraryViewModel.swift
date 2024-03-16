//
//  LibraryViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class LibraryViewModel: ViewModel {
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<MusicItem>
    }
    
    struct Output {
        let playlist: Driver<[(title: String, item: MusicItemCollection<Track>)]>
        let artists: Driver<MusicItemCollection<Artist>>
        let likes: Driver<MusicItemCollection<Track>>
        let recentlyPlaylist: Driver<MusicItemCollection<Track>>
        let albums: Driver<MusicItemCollection<Album>>
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
    
    // MARK: - Lifecycles
    
    init(coordinator: LibraryCoordinator?) {
        self.coordinator = coordinator
    }
    
    func transform(_ input: Input) -> Output {
        
        let playlist = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchPlaylist()
            }.asDriver(onErrorJustReturn: [])
        
        let artist = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchArtistList()
            }.asDriver(onErrorJustReturn: [])
        
        let likes = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchLikeList()
            }.asDriver(onErrorJustReturn: [])
        
        let recentlyPlaylist = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchRecentlyPlayList()
            }.asDriver(onErrorJustReturn: [])
        
        let albums = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchAlbumList()
            }.asDriver(onErrorJustReturn: [])
        
        input.itemSelected.withUnretained(self).subscribe { owner, item in
            //            owner.coordinator?.pushToList(item: item)
        }.disposed(by: disposeBag)
        
        return Output(playlist: playlist,
                      artists: artist,
                      likes: likes,
                      recentlyPlaylist: recentlyPlaylist,
                      albums: albums)
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
    
    private func fetchLikeList() -> Observable<MusicItemCollection<Track>> {
        return Observable.create { [weak self] observer in
            guard let self,
                  let likes = likesRepository.fetchArr().first
            else { return Disposables.create() }
            Task {
                do {
                    let result = try await self.musicRepository.requestLikeList(ids: Array(likes.likeID))
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
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
}
