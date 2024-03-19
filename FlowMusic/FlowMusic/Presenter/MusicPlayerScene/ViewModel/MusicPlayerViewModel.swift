//
//  MusicPlayerViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Combine
import Foundation
import MusicKit

import RxSwift
import RxCocoa

final class MusicPlayerViewModel: ViewModel {
    
    struct Input {
        let chevronButtonTapped: ControlEvent<Void>
        let viewWillAppear: Observable<Void>
        let playButtonTapped: Observable<Void>
        let previousButtonTapped: ControlEvent<Void>
        let nextButtonTapped: ControlEvent<Void>
        let repeatButtonTapped: Observable<Void>
        let shuffleButtonTapped: Observable<Void>
        let heartButtonTapped: Observable<(Bool)>
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
    let musicPlayer = FMMusicPlayer()
    private let musicRepository = MusicRepository()
    private let userLikeRepository = UserRepository<UserLikeList>()
    private let setting = UserDefaultsManager.shared
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private lazy var playStateSubject = BehaviorSubject<ApplicationMusicPlayer.PlaybackStatus>(value: musicPlayer.getPlaybackState())
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicPlayerCoordinator?, track: Track) {
        self.coordinator = coordinator
        //선택한 track 넣어서 뷰로
        trackSubject.onNext(track)
        //음악플레이어 상태 추적(API기본제공 컴바인)
        playerUpdateSink()
        playerStateUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        input
            .chevronButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.coordinator?.dismissViewController()
            }.disposed(by: disposeBag)
        
        input.playButtonTapped
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
        
        input.previousButtonTapped
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.nextButtonTapped
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
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
            .flatMap { owner, mode in
                return owner.setRepeatButton(mode: mode)
            }.asDriver(onErrorJustReturn: .off)
        
        let shuffleMode = input.shuffleButtonTapped
            .map { [weak self]  _ -> ShuffleMode in
                guard let self else { return .off }
                setting.userSetting.shuffleMode.toggle()
                let mode = setting.userSetting.shuffleMode
                musicPlayer.setShuffleMode(mode: mode)
                return mode
            }
            .withUnretained(self)
            .flatMap { owner, mode in
                return owner.setShuffleButton(mode: mode)
            }.asDriver(onErrorJustReturn: .off)
        
        let isHeart = input
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
                print(userLikeRepository.fetchArr())
            }
            .asDriver(onErrorJustReturn: false)
        
        input.viewWillDisappear
            .withUnretained(self)
            .subscribe{ owner, _ in
                owner.coordinator?.finish()
            }.disposed(by: disposeBag)
        
        return Output(updateEntry: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playStateSubject.asDriver(onErrorJustReturn: .playing),
                      repeatMode: repeatMode,
                      shuffleMode: shuffleMode,
                      isHeart: isHeart)
    }
    
    func setTrack(track: Track) -> Observable<Track> {
        return Observable.create { observer in
            observer.onNext(track)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func setRepeatButton(mode: RepeatMode) -> Observable<RepeatMode> {
        return Observable.create { observer in
            observer.onNext(mode)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func setShuffleButton(mode: ShuffleMode) -> Observable<ShuffleMode> {
        return Observable.create { observer in
            observer.onNext(mode)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}
 
extension MusicPlayerViewModel {
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
