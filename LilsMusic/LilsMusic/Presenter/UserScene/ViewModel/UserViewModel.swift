//
//  UserViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation

final class UserViewModel {
    
    weak var coordinator: UserCoordinator?
    
    init(coordinator: UserCoordinator?) {
        self.coordinator = coordinator
    }
    
}
