//
//  MusicPlayerViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Combine
import Foundation
import MusicKit

import RxRelay
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
        let viewDidDisappear: Observable<Void>
    }
    
    struct Output {
        let updateEntry: Driver<Track?>
        let playState:  Driver<Bool>
        let repeatMode: Driver<Bool>
        let shuffleMode: Driver<Bool>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicPlayerCoordinator?
    let player = MusicPlayerManager.shared
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
                    try await bool ? owner.player.pause() : owner.player.play()
                }
            }
            .flatMap { owner, bool in
                owner.setPlayButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
        input.previousButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.player.skipToPrevious()
                }
            }.disposed(by: disposeBag)
        
        input.nextButtonTapped
            .withUnretained(self)
            .subscribe { owner, _ in
                Task {
                    try await owner.player.skipToNext()
                }
            }.disposed(by: disposeBag)
        
        let repeatMode = input.repeatButtonTapped
            .map { !$0 }
            .withUnretained(self)
            .do { owner, bool in
                UserDefaultsManager.shared.isRepeat = bool
                owner.player.setRepeatMode(isRepeat: bool)
                print(UserDefaultsManager.shared.isRepeat)
                print(owner.player.player.state.repeatMode)
            }
            .flatMap { owner, bool in
                owner.setRepeatButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
        let shuffleMode = input.shuffleButtonTapped
            .map { !$0 }
            .withUnretained(self)
            .do { owner, bool in
                UserDefaultsManager.shared.isShuffle = bool
                owner.player.setShuffleMode(isShuffle: bool)
                print(UserDefaultsManager.shared.isShuffle)
                print(owner.player.player.state.shuffleMode)
            }
            .flatMap { owner, bool in
                owner.setShuffleButton(isSelected: bool)
            }.asDriver(onErrorJustReturn: true)
        
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
        player.getCurrentPlayer().queue.objectWillChange.sink { [weak self] _  in
            guard let self else { return }
            Task { [weak self] in
                guard let self,
                      let entry = player.getCurrentEntry(),
                      let song = try await musicRepository.requestSearchSongIDCatalog(id: entry.item?.id) else { return }
                let track = Track.song(song)
                trackSubject.onNext(track)
            }
        }.store(in: &cancellables)
    }
}
