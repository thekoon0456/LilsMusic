//
//  MusicRecommendViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation
import MusicKit

import RxCocoa
import RxRelay
import RxSwift

final class MusicRecommendViewModel: ViewModel {
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let recommendSongs: Driver<MusicItemCollection<Song>>
        let recommendPlaylists: Driver<MusicItemCollection<Playlist>>
        let recommendAlbums: Driver<MusicItemCollection<Album>>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
    private let musicRepository = MusicRepository()
    private let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
    }
    
    func transform(_ input: Input) -> Output {
        print(#function)
        let songs = input.viewWillAppear
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendSongs()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Song>())

        let playlists = input.viewWillAppear
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendPlaylists()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Playlist>())
        
        let albums = input.viewWillAppear
            .withUnretained(self)
            .flatMapLatest { owner, void in
                owner.fetchRecommendAlbums()
            }
            .asDriver(onErrorJustReturn: MusicItemCollection<Album>())
        
        return Output(recommendSongs: songs,
                      recommendPlaylists: playlists,
                      recommendAlbums: albums)
    }
    
    func fetchRecommendSongs() -> Observable<MusicItemCollection<Song>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let songs = try await musicRepository.requestCatalogSongCharts()
                    print(songs)
                    observer.onNext(songs)
                    observer.onCompleted()
                } catch {
                    print("Error fetching songs: \(error)")
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
