//
//  MusicListViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import Foundation
import MusicKit

final class MusicListViewModel: ViewModel {
    
    struct Input {
//        let listTapped = Observable<Track?>(nil)
    }
    
    struct Output {
        
    }
    
    weak var coordinator: MusicListCoordinator?
    let input = Input()
    let output = Output()
    
    init(coordinator: MusicListCoordinator?) {
        self.coordinator = coordinator
//        transform()
    }
    
//    private func transform() {
//        input.listTapped.bind { [weak self] track in
//            guard let self,
//                  let track else { return }
//            coordinator?.present(track: track)
//        }
//    }
    
    
    
}
