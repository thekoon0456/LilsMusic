//
//  MusicPlayerViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation

final class MusicPlayerViewModel: ViewModel {
    
    weak var coordinator: MusicPlayerCoordinator?
    
    init(coordinator: MusicPlayerCoordinator?) {
        self.coordinator = coordinator
    }
    
    
}
