//
//  MusicListCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit
import MusicKit

final class MusicListCoordinator: Coordinator, CoordinatorDelegate {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    var item: MusicItem //album, playlist
    
    init(navigationController: UINavigationController?, item: MusicItem) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicList
        self.item = item
    }
    
    func start() {
        let vm = MusicListViewModel(coordinator: self)
        let vc = MusicListViewController(viewModel: vm, item: item)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func present(track: Track) {
        let coordinator = MusicPlayerCoordinator(navigationController: navigationController,
                                                 track: track)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func didFinish(childCoordinator: any Coordinator) {
        childCoordinators.forEach { coordinator in
            if let musicCoordinator = coordinator as? MusicPlayerCoordinator {
                childCoordinators.removeAll { coordinator in
                    musicCoordinator === coordinator
                }
            }
        }
    }
}
