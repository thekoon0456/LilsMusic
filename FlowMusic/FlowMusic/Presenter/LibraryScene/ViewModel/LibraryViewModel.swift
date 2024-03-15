//
//  LibraryViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation
import MusicKit

final class LibraryViewModel: ViewModel {
    
//    struct Input {
//        let push = Observable<Album?>(nil)
//    }
//    
//    struct Output {
//        
    
    // MARK: - Properties
    
    weak var coordinator: LibraryCoordinator?
//    let input = Input()
//    let output = Output()
    
    // MARK: - Lifecycles
    
    init(coordinator: LibraryCoordinator?) {
        self.coordinator = coordinator
    }
    
//    private func transform() {
//        input.push.bind { [weak self] album in
//            guard let self else { return }
//            coordinator.present
//            
//        }
//    }
    
    
    
}
