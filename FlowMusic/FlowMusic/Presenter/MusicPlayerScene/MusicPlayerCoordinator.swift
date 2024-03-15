//
//  MusicPlayerCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class MusicPlayerCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    var track: Track
    
    init(navigationController: UINavigationController?, track: Track) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicPlayer
        self.track = track
    }
    
    func start() {
        let vm = MusicPlayerViewModel(coordinator: self, track: track)
        let vc = MusicPlayerViewController(viewModel: vm)
        navigationController?.present(vc, animated: true)
    }
}
