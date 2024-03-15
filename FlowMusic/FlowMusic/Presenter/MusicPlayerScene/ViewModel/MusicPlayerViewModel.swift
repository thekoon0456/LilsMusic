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
        let repeatButtonTapped: ControlEvent<Void>
        let shuffleButtonTapped: ControlEvent<Void>
        let viewDidDisappear: Observable<Void>
    }
    
    struct Output {
        let updateEntry: Driver<Track?>
        let playState:  Driver<Bool>
//        let repeatMode: Driver<Bool>
//        let shuffleMode: Driver<Bool>
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicPlayerCoordinator?
    let player = MusicPlayerManager.shared
    private let userDefaultManager = UserDefaultsManager.shared
    let musicRepository = MusicRepository()
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    //사용자가 선택한 track
    let trackSubject = BehaviorSubject<Track?>(value: nil)
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicPlayerCoordinator?, track: Track) {
        self.coordinator = coordinator
        trackSubject.onNext(track)
        playerUpdateSink()
    }
    
    func transform(_ input: Input) -> Output {
        let playState = input.playButtonTapped
            .map { bool in
                var bool = bool
                bool.toggle()
                return bool
            }
            .withUnretained(self)
            .do { owner, bool in
                Task {
                    try await bool
                    ? owner.player.pause()
                    : owner.player.play()
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
        

//        input.nextButtonTapped
//            .withUnretained(self)
//            .subscribe { owner in
//                owner.player.skipToNext()
//            }.disposed(by: disposeBag)
//        
//        let shuffleMode = input.shuffleButtonTapped
        
        
       
        return Output(updateEntry: trackSubject.asDriver(onErrorJustReturn: nil),
                      playState: playState)
//                      repeatMode: shuffleMode.asObservable(),
//                      shuffleMode: shuffleMode)
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
//    
//    func setPreviousButton() -> Observable<Bool> {
//        return Observable.create { observer in
//            observer.onNext(track)
//            observer.onCompleted()
//            return Disposables.create()
//        }
//    }
//    
//    func setNextButton() -> Observable<Bool> {
//        return Observable.create { observer in
//            observer.onNext(track)
//            observer.onCompleted()
//            return Disposables.create()
//        }
//    }
//    
//    func setShuffleButton() -> Observable<Bool> {
//        return Observable.create { observer in
//            observer.onNext(userDefaultManager.isShuffle)
//            observer.onCompleted()
//            return Disposables.create()
//        }
//    }
//    
//    func setRepeatButton() -> Observable<Bool> {
//        return Observable.create { observer in
//            observer.onNext(userDefaultManager.isRepeat)
//            observer.onCompleted()
//            return Disposables.create()
//        }
//    }
    
    func playerUpdateSink() {
        player.getCurrentPlayer().queue.objectWillChange.sink { [weak self] _  in
            guard let self else { return }
            let entry = player.getCurrentEntry()
            Task { [weak self] in
                guard let self, let song = try await musicRepository.requestSearchSongIDCatalog(id: entry?.item?.id) else { return }
                let track = Track.song(song)
                trackSubject.onNext(track)
            }
        }.store(in: &cancellables)
    }
}
