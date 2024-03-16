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
        let viewWillAppear: Observable<Void>
        let playButtonTapped: Observable<Bool>
        let previousButtonTapped: ControlEvent<Void>
        let nextButtonTapped: ControlEvent<Void>
        let repeatButtonTapped: Observable<Bool>
        let shuffleButtonTapped: Observable<Bool>
        let viewWillDisappear: Observable<Void>
    }
    
    struct Output {
        let updateEntry: Driver<Track?>
        let playState:  Driver<Bool>
        let repeatMode: Driver<Bool>
        let shuffleMode: Driver<Bool>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicPlayerCoordinator?
    let musicPlayer = MusicPlayerManager()
    let musicRepository = MusicRepository()
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    let trackSubject = BehaviorSubject<Track?>(value: nil)
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicPlayerCoordinator?, track: Track) {
        self.coordinator = coordinator
        //선택한 track 넣어서 뷰로
        trackSubject.onNext(track)
        //음악플레이어 상태 추적(API기본제공 컴바인)
        playerUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        let playState = input.playButtonTapped
            .map { !$0 }
            .withUnretained(self)
            .do { owner, bool in
                Task {
                    try await bool ? owner.musicPlayer.pause() : owner.musicPlayer.play()
                }
            }
            .flatMap { owner, bool in
                owner.setPlayButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
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
            .map { !$0 }
            .withUnretained(self)
            .do { owner, bool in
                UserDefaultsManager.shared.isRepeat = bool
                owner.musicPlayer.setRepeatMode(isRepeat: bool)
                print(UserDefaultsManager.shared.isRepeat)
                //                print(owner.musicPlayer.player.state.repeatMode)
            }
            .flatMap { owner, bool in
                owner.setRepeatButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
        let shuffleMode = input.shuffleButtonTapped
            .map { !$0 }
            .withUnretained(self)
            .do { owner, bool in
                UserDefaultsManager.shared.isShuffle = bool
                owner.musicPlayer.setShuffleMode(isShuffle: bool)
                print(UserDefaultsManager.shared.isShuffle)
                //                print(owner.musicPlayer.player.state.shuffleMode)
            }
            .flatMap { owner, bool in
                owner.setShuffleButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
        input.viewWillDisappear
            .withUnretained(self)
            .subscribe{ owner, _ in
                owner.coordinator?.finish()
            }.disposed(by: disposeBag)
        
        return Output(updateEntry: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playState,
                      repeatMode: repeatMode,
                      shuffleMode: shuffleMode)
    }
    
    func setTrack(track: Track) -> Observable<Track> {
        return Observable.create { observer in
            observer.onNext(track)
            observer.onCompleted()
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
    
    func setRepeatButton(isSelected: Bool) -> Observable<Bool> {
        return Observable.create { observer in
            observer.onNext(isSelected)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    func setShuffleButton(isSelected: Bool) -> Observable<Bool> {
        return Observable.create { observer in
            observer.onNext(isSelected)
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    //플레이어 상태 추적, 업데이트
    func playerUpdateSink() {
        musicPlayer.getCurrentPlayer().queue.objectWillChange.sink { _  in
            Task { [weak self] in
                guard let self,
                      let entry = try await musicPlayer.getCurrentEntry(),
                      let song = try await self.musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
                let track = Track.song(song)
                self.trackSubject.onNext(track)
            }
        }.store(in: &cancellables)
    }
}
