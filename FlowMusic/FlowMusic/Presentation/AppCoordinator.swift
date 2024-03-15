//
//  AppCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class AppCoordinator: Coordinator {

    // MARK: - Properties
    
    weak var delegate: CoordinatorDelegate?
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinator]
    var type: CoordinatorType
    
    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
        self.childCoordinators = []
        self.type = .app
    }
    
    // MARK: - Helpers
    
    func start() {
        //TODO: -온보딩 분기처리
        Task {
            await requestMusicAuthorization()
        }

        let tabBarController = UITabBarController()
        tabBarController.tabBar.backgroundColor = .systemBackground
        
        let recommendNav = UINavigationController()
        let recommendCoordinator = MusicRecommendCoordinator(navigationController: recommendNav)
        childCoordinators.append(recommendCoordinator)
        recommendCoordinator.start()
        
        let reelsNav = UINavigationController()
        let reelsCoordinator = ReelsCoordinator(navigationController: reelsNav)
        childCoordinators.append(reelsCoordinator)
        reelsCoordinator.start()
        
        let libraryNav = UINavigationController()
        let libraryCoordinator = LibraryCoordinator(navigationController: libraryNav)
        childCoordinators.append(libraryCoordinator)
        libraryCoordinator.start()
        
        let userNav = UINavigationController()
        let userCoordinator = UserCoordinator(navigationController: userNav)
        childCoordinators.append(userCoordinator)
        userCoordinator.start()
        
        tabBarController.viewControllers = [recommendNav, reelsNav, libraryNav, userNav]
        navigationController?.pushViewController(tabBarController, animated: false)
    }
}
