//
//  TrendingViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
////
//
//import Foundation
//import MusicKit
//
//import RxSwift
//
//final class TrendingViewModel: ViewModel {
//    
//    struct Input {
////        let push = Observable<Album?>(nil)
//        let viewDidLoadTrigger: Observable<Void>
//        let itemSelected
//    }
//    
//    struct Output {
//        
//    }
//    
//    // MARK: - Properties
//    
//    weak var coordinator: MusicRecommendCoordinator?
//    
//    // MARK: - Lifecycles
//    
//    init(coordinator: MusicRecommendCoordinator?) {
//        self.coordinator = coordinator
//    }
//    
////    private func transform() {
////        input.push.bind { [weak self] album in
////            guard let self,
////                  let album else { return }
////            coordinator?.push(album: album)
////        }
////    }
//    
//    
//}
