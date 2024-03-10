//
//  MusicRecommendViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation

final class MusicRecommendViewModel: ViewModel {
    
    weak var coordinator: MusicRecommendCoordinator?
    
    init(coordinator: MusicRecommendCoordinator? = nil) {
        self.coordinator = coordinator
    }
}
