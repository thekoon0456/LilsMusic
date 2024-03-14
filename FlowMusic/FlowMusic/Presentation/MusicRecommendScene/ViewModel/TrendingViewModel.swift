//
//  TrendingViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import Foundation
import MusicKit

final class TrendingViewModel: ViewModel {
    
    struct Input {
//        let push = Observable<Album?>(nil)
    }
    
    struct Output {
        
    }
    
    // MARK: - Properties
    
    weak var coordinator: MusicRecommendCoordinator?
//    let input = Input()
//    let output = Output()
    
    // MARK: - Lifecycles
    
    init(coordinator: MusicRecommendCoordinator?) {
        self.coordinator = coordinator
//        transform()
    }
    
//    private func transform() {
//        input.push.bind { [weak self] album in
//            guard let self,
//                  let album else { return }
//            coordinator?.push(album: album)
//        }
//    }
    
    
}
