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
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    private let trackSubject = BehaviorSubject<Track?>(value: nil)
    private lazy var playStateSubject = BehaviorSubject<ApplicationMusicPlayer.PlaybackStatus>(value: musicPlayer.getPlaybackState())
    private let heartSubject = BehaviorSubject<Bool>(value: false)
    
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
        input.viewWillAppear
            .map { [weak self] _ in
                guard let self else { return false }
                return checkHeart()
            }
            .withUnretained(self)
            .subscribe{ owner, bool in
                owner.heartSubject.onNext(bool)
            }.disposed(by: disposeBag)
        
        input.chevronButtonTapped
            .observe(on:MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe { owner, _ in
                owner.coordinator?.dismissViewController()
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.playButtonTapped
            .observe(on:MainScheduler.asyncInstance)
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
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.previousButtonTapped
            .observe(on:MainScheduler.asyncInstance)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.musicPlayer.skipToPrevious()
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        input.nextButtonTapped
            .observe(on:MainScheduler.asyncInstance)
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .withUnretained(self)
            .subscribe { owner, _ in
                //큐에 한곡만 남았을때는 넘기지 않음.
                guard owner.musicPlayer.getQueue().count > 1 else { return }
                Task {
                    try await owner.musicPlayer.skipToNext()
                }
                owner.tapImpact()
            }.disposed(by: disposeBag)
        
        let repeatMode = input.repeatButtonTapped
            .observe(on:MainScheduler.asyncInstance)
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
            .observe(on:MainScheduler.asyncInstance)
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
        
        input
            .heartButtonTapped
            .map {!$0 }
            .observe(on:MainScheduler.asyncInstance)
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
            .withUnretained(self)
            .subscribe{ owner, _ in
                owner.coordinator?.finish()
            }.disposed(by: disposeBag)
        
        return Output(updateEntry: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playStateSubject.asDriver(onErrorJustReturn: musicPlayer.getPlaybackState()),
                      repeatMode: repeatMode,
                      shuffleMode: shuffleMode,
                      isHeart: heartSubject.asDriver(onErrorJustReturn: false))
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
    
    func checkHeart() -> Bool {
        guard let item = userLikeRepository.fetchArr().first,
              let id = try? trackSubject.value()?.id.rawValue
        else { return false }
        return item.likeID.contains { $0 == id }
    }
}
 
extension MusicPlayerViewModel {
    //플레이어 상태 추적, 업데이트
    func playerUpdateSink() {
        musicPlayer.getCurrentPlayer().queue.objectWillChange
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .dropFirst() //처음 뷰 진입시 트랙 가지고옴
            .sink { _ in
            Task { [weak self] in
                guard let self,
                      let entry = try await musicPlayer.getCurrentEntry(),
                      let song = try await musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
                let track = Track.song(song)
                trackSubject.onNext(track)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let bool = checkHeart()
                    heartSubject.onNext(bool)
                }
            }
        }.store(in: &cancellables)
    }
    
    //음악 재생상태 추적, 업데이트
    func playerStateUpdateSink() {
        musicPlayer.getCurrentPlayer().state.objectWillChange
            .sink { [weak self] _ in
            guard let self else { return }
            let state = musicPlayer.getPlaybackState()
            playStateSubject.onNext(state)
        }.store(in: &cancellables)
    }
}
