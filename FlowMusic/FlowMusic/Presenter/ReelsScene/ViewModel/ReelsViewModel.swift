//
//  ReelsViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation

final class ReelsViewModel: ViewModel {
    
    weak var coordinator: ReelsCoordinator?
    
    init(coordinator: ReelsCoordinator?) {
        self.coordinator = coordinator
    }
    
    
}
