//
//  LibraryListCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/22/24.
//

import Foundation

import UIKit
import MusicKit

final class LibraryListCoordinator: Coordinator, CoordinatorDelegate {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    var tracks: MusicItemCollection<Track>
    
    init(navigationController: UINavigationController?, tracks: MusicItemCollection<Track>) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicList
        self.tracks = tracks
    }
    
    func start() {
        let vm = LibraryListViewModel(coordinator: self, tracks: tracks)
        
        let vc = LibraryListViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
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
