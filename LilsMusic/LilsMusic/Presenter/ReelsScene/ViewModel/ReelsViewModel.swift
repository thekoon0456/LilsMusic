//
//  ReelsViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation
import MusicKit

import RxCocoa
import RxSwift

final class ReelsViewModel: ViewModel {
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let mvList: Driver<MusicItemCollection<MusicVideo>>
    }
    
    // MARK: - Properties
    
    weak var coordinator: ReelsCoordinator?
    let disposeBag = DisposeBag()
    private let musicAPIManager = MusicAPIManager.shared
    let mvSubject = BehaviorSubject<MusicItemCollection<MusicVideo>>(value: [])
    
    // MARK: - Lifecycles
    
    init(coordinator: ReelsCoordinator?) {
        self.coordinator = coordinator
    }
    
    // MARK: - Helpers
    
    func transform(_ input: Input) -> Output {
        
        let mvList = input
            .viewWillAppear
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.fetchMovieList()
            }
            .asDriver(onErrorJustReturn: [])
        
        return Output(mvList: mvList)
    }
    
    private func fetchMovieList() -> Observable<MusicItemCollection<MusicVideo>> {
        return Observable.create { [weak self] observer in
            guard let self else { return Disposables.create() }
            Task {
                do {
                    let result = try await self.musicAPIManager.requestCatalogMVCharts()
                    observer.onNext(result)
                    observer.onCompleted()
                    self.mvSubject.onNext(result)
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
}
