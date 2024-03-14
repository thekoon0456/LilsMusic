//
//  MusicListCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit
import MusicKit

final class MusicListCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    var album: Album
    
    init(navigationController: UINavigationController?, album: Album) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicList
        self.album = album
    }
    
    func start() {
        let album = MusicItemCollection(arrayLiteral: album)
        let vm = MusicListViewModel(coordinator: self)
        let vc = MusicListViewController(viewModel: vm, album: album)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func present(track: Track) {
        let coordinator = MusicPlayerCoordinator(navigationController: navigationController,
                                                 track: track)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    
}
