//
//  MusicRecommendCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class MusicRecommendCoordinator: Coordinator, CoordinatorDelegate {

    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .recommend
    }
    
    func start() {
        let vm = MusicRecommendViewModel(coordinator: self)
        let vc = MusicRecommendViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: nil,
                                     image: UIImage(systemName: FMDesign.Icon.recommend.name),
                                     selectedImage: UIImage(systemName: FMDesign.Icon.recommend.fill))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func pushToList(item: MusicItem) {
        let listCoordinator = MusicListCoordinator(navigationController: navigationController,
                                                   item: item)
        listCoordinator.delegate = self
        childCoordinators.append(listCoordinator)
        listCoordinator.start()
    }
    
    func presentMusicPlayer(track: Track) {
        let coordinator = MusicPlayerCoordinator(navigationController: navigationController,
                                                 track: track)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func didFinish(childCoordinator: any Coordinator) {
        finish()
    }
}
