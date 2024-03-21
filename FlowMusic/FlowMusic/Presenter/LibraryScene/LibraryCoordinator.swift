//
//  LibraryCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class LibraryCoordinator: Coordinator, CoordinatorDelegate {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .library
    }
    
    func start() {
        let vm = LibraryViewModel(coordinator: self)
        let vc = LibraryViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: nil,
                                     image: UIImage(systemName: FMDesign.Icon.library.name),
                                     selectedImage: UIImage(systemName: FMDesign.Icon.library.fill))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func pushToList(album: Album) {
        let coordinator = MusicListCoordinator(navigationController: navigationController,
                                              item: album)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func pushToList(playlist: Playlist) {
        let coordinator = MusicListCoordinator(navigationController: navigationController,
                                              item: playlist)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func pushToList(track: MusicItemCollection<Track>?) {
        guard let track = track as? MusicItem else { return }
        let coordinator = MusicListCoordinator(navigationController: navigationController,
                                               item: track)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func presentMusicPlayer(track: Track) {
        let coordinator = MusicPlayerCoordinator(navigationController: navigationController,
                                                 track: track)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func didFinish(childCoordinator: any Coordinator) {
        childCoordinators = []
    }
}
