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
    }
    
    struct Output {
        let currentPlaySong: Driver<Track?>
        let recommendSongs: Driver<MusicItemCollection<Song>>
        let recommendPlaylists: Driver<MusicItemCollection<Playlist>>
        let recommendAlbums: Driver<MusicItemCollection<Album>>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicPlayer = MusicPlayerManager()
    private let musicRepository = MusicRepository()
    let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
    }
    
    func transform(_ input: Input) -> Output {
        let currentPlaySong = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, void in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
        
        input.miniPlayerTapped
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
            .drive(with: self) { owner, track in
                guard let track else { return }
                owner.coordinator?.presentMusicPlayer(track: track)
            }.disposed(by: disposeBag)
        
        let songs = input.viewDidLoad
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendSongs()
            }.asDriver(onErrorJustReturn: MusicItemCollection<Song>())
        
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
        
        input.itemSelected.withUnretained(self).subscribe { owner, item in
            owner.coordinator?.pushToList(item: item)
        }.disposed(by: disposeBag)
        
        return Output(currentPlaySong: currentPlaySong,
                      recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums)
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
    
    func fetchRecommendSongs() -> Observable<MusicItemCollection<Song>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let songs = try await musicRepository.requestCatalogSongCharts()
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
}
