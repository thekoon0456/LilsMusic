//
//  ReelsCellViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/25/24.
//

import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class ReelsCellViewModel: ViewModel {
    
    struct Input {
        let mv: Observable<MusicVideo?>
        let heartButtonTapped: Observable<Bool>
    }
    
    struct Output {
        let isHeart: Driver<(Bool)>
    }
    
    // MARK: - Properties
    
    private let musicAPIManager = MusicAPIManager.shared
    private let userLikeRepository = UserRepository<UserLikeList>()
    let disposeBag = DisposeBag()
    private let mvSubject = BehaviorSubject<MusicVideo?>(value: nil)
    private let heartSubject = BehaviorSubject<Bool>(value: false)
    
    // MARK: - Helpers
    
    func transform(_ input: Input) -> Output {
        
        input.mv
            .withUnretained(self)
            .subscribe { owner, mv in
                owner.mvSubject.onNext(mv)
                Task {
                    let track = try await owner.getMusicID(item: mv)
                    guard let id = track?.id else { return }
                    DispatchQueue.main.async {
                        let bool = owner.checkHeart(id: id.rawValue)
                        owner.heartSubject.onNext(bool)
                    }
                }
            }.disposed(by: disposeBag)
        
        input
            .heartButtonTapped
            .map {!$0 }
            .do { [weak self] bool in
                guard let self,
                      let item = userLikeRepository.fetchArr().first,
                      let mv = try? mvSubject.value()
                else { return }
                Task { [weak self] in
                    guard let self else { return }
                    guard let id = try await getMusicID(item: mv)?.id.rawValue else { return }
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        bool
                        ? userLikeRepository.updateUserLikeList(item, id: id)
                        : userLikeRepository.deleteUserLikeList(item, id: id)
                        tapImpact()
                    }
                }
            }
            .observe(on:MainScheduler.asyncInstance)
            .withUnretained(self)
            .subscribe { owner, bool in
                owner.heartSubject.onNext(bool)
            }
            .disposed(by: disposeBag)
        
        return Output(isHeart: heartSubject.asDriver(onErrorJustReturn: false))
    }
    
    
    func checkHeart(id: String) -> Bool {
        guard let item = userLikeRepository.fetchArr().first else { return false }
        return item.likeID.contains { $0 == id }
    }
    
    func getMusicID(item: MusicVideo?) async throws -> Track?  {
        guard let item,
              let song = try await musicAPIManager.MusicVideoToSong(item)
        else { return nil }
        return Track.song(song)
    }
}
