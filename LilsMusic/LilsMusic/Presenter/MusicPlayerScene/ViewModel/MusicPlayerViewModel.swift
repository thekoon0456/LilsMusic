//
//  MusicPlayerViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit

import RxSwift
import RxCocoa

final class MusicPlayerViewModel: ViewModel {
    
    struct Input {
        let chevronButtonTapped: ControlEvent<Void>
        let viewWillAppear: Observable<Void>
        let playButtonTapped: Observable<Void>
        let previousButtonTapped: Observable<Void>
        let nextButtonTapped: Observable<Void>
        let repeatButtonTapped: Observable<Void>
        let shuffleButtonTapped: Observable<Void>
        let heartButtonTapped: Observable<Bool>
        let playlistButtonTapped: Observable<String>
        let viewWillDisappear: Observable<Void>
    }
    
    struct Output {
        let updateEntry: Driver<Track?>
        let playState:  Driver<ApplicationMusicPlayer.PlaybackStatus>
        let repeatMode: Driver<RepeatMode>
        let shuffleMode: Driver<ShuffleMode>
        let isHeart: Driver<(Bool)>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicPlayerCoordinator?
    let musicPlayer = FMMusicPlayer.shared
    private let musicRepository = MusicRepository()
    private let userLikeRepository = UserRepository<UserLikeList>()
    private let setting = UserDefaultsManager.shared
    let disposeBag = DisposeBag()
    private let heartSubject = BehaviorSubject<Bool>(value: false)
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    // MARK: - Lifecycles
    
    init(coordinator: MusicPlayerCoordinator?, track: Track) {
        self.coordinator = coordinator
        self.trackSubject.onNext(track)
    }
    
    deinit {
        print("MusicPlayerViewModel, Deinit")
    }
    
    func transform(_ input: Input) -> Output {
        
        musicPlayer.currentEntrySubject
            .asObservable()
            .withUnretained(self)
            .flatMapLatest { owner, entry in
                owner.fetchCurrentEntryTrackObservable(entry: entry)
            }
            .subscribe(with: self) { owner, track in
                owner.trackSubject.onNext(track)
            }.disposed(by: disposeBag)
        
        input.viewWillAppear
            .map { [weak self] _ in
                guard let self else { return false }
                return checkHeart()
            }
            .subscribe(with: self){ owner, bool in
                owner.heartSubject.onNext(bool)
            }.disposed(by: disposeBag)
        
        input.chevronButtonTapped
            .bind(with: self) { owner, _ in
                owner.coordinator?.dismissViewController()
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.playButtonTapped
            .bind(with: self) { owner, _ in
                let state = owner.musicPlayer.getPlaybackState()
                if state == .playing {
                    owner.musicPlayer.pause()
                } else {
                    Task {
                        try await owner.musicPlayer.play()
                    }
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.previousButtonTapped
            .bind(with: self) { owner, _ in
                owner.tapImpact()
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.nextButtonTapped
            .bind(with: self) { owner, _ in
                owner.tapImpact()
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        let repeatMode = input.repeatButtonTapped
            .map { [weak self]  _ -> RepeatMode in
                guard let self else { return .off }
                setting.userSetting.repeatMode.toggle()
                let mode = setting.userSetting.repeatMode
                musicPlayer.setRepeatMode(mode: mode)
                return mode
            }
            .withUnretained(self)
            .flatMapLatest { owner, mode in
                owner.setRepeatButtonObservable(mode: mode)
            }.asDriver(onErrorJustReturn: .off)
        
        let shuffleMode = input.shuffleButtonTapped
            .map { [weak self]  _ -> ShuffleMode in
                guard let self else { return .off }
                setting.userSetting.shuffleMode.toggle()
                let mode = setting.userSetting.shuffleMode
                print(mode)
                musicPlayer.setShuffleMode(mode: mode)
                return mode
            }
            .withUnretained(self)
            .flatMapLatest { owner, mode in
                owner.setShuffleButtonObservable(mode: mode)
            }.asDriver(onErrorJustReturn: .off)
        
        input
            .heartButtonTapped
            .map {!$0 }
            .do { [weak self] bool in
                guard let self,
                      let item = userLikeRepository.fetchArr().first,
                      let id = try? trackSubject.value()?.id.rawValue
                else { return }
                bool
                ? userLikeRepository.updateUserLikeList(item, id: id)
                : userLikeRepository.deleteUserLikeList(item, id: id)
                tapImpact()
            }
            .withUnretained(self)
            .subscribe { owner, bool in
                owner.heartSubject.onNext(bool)
            }.disposed(by: disposeBag)
        
        input.viewWillDisappear
            .subscribe(with: self) { owner, _ in
                owner.coordinator?.finish()
            }.disposed(by: disposeBag)
        
        return Output(updateEntry: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: musicPlayer.currentPlayStateSubject.asDriver(onErrorJustReturn: .playing),
                      repeatMode: repeatMode,
                      shuffleMode: shuffleMode,
                      isHeart: heartSubject.asDriver(onErrorJustReturn: false))
    }
    
    func setRepeatButtonObservable(mode: RepeatMode) -> Observable<RepeatMode> {
        return Observable.create { observer in
            observer.onNext(mode)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func setShuffleButtonObservable(mode: ShuffleMode) -> Observable<ShuffleMode> {
        return Observable.create { observer in
            observer.onNext(mode)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func checkHeart() -> Bool {
        guard let item = userLikeRepository.fetchArr().first,
              let id = try? trackSubject.value()?.id.rawValue
        else { return false }
        return item.likeID.contains { $0 == id }
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
    }
}
