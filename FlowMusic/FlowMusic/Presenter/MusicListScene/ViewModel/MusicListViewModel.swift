//
//  MusicListViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class MusicListViewModel: ViewModel {
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<(index: Int, track: Track)>
        let miniPlayerTapped: Observable<Void>
    }
    
    struct Output {
        let item: Driver<MusicItem?>
        let tracks: Driver<MusicItemCollection<Track>>
        let currentPlaySong: Driver<Track?>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicListCoordinator?
    
    private let musicPlayer = MusicPlayerManager()
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
        
        let currentPlaySong = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, void in
                owner.getCurrentPlaySong()
            }.asDriver(onErrorJustReturn: nil)
        
        input.itemSelected
            .withUnretained(self)
            .subscribe { owner, item in
                owner.coordinator?.presentMusicPlayer(track: item.track)
                Task {
                    guard let tracks = try await owner.fetchTracks() else { return }
                    try await owner.musicPlayer.setTrackQueue(item: tracks, startIndex:item.index)
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
        
        let tracks = getTracks().asDriver(onErrorJustReturn: MusicItemCollection<Track>())
        
        return Output(item: musicItem.asDriver(onErrorJustReturn: nil),
                      tracks: tracks,
                      currentPlaySong: currentPlaySong)
    }
    
    func getTracks() -> Observable<MusicItemCollection<Track>> {
        return Observable.create { observer in
            Task { [weak self] in
                guard let self,
                      let item = try? musicItem.value()
                else { return }
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
        do {
            switch item {
            case let playlist as Playlist:
                return try await musicRepository.playlistToTracks(playlist)
            case let album as Album:
                return try await musicRepository.albumToTracks(album)
            default:
                return nil
            }
        } catch {
            return nil
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
