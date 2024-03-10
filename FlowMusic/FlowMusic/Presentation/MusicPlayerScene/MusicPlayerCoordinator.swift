//
//  MusicPlayerCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class MusicPlayerCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicPlayer
    }
    
    func start(track: Track) {
        let vm = MusicPlayerViewModel(coordinator: self)
        let vc = MusicPlayerViewController(viewModel: vm, track: track)
        navigationController?.present(vc, animated: true)
    }
    
    
}
