//
//  AppCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class AppCoordinator: Coordinator {

    // MARK: - Properties
    
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
        let tabBarController = UITabBarController()
        let recommendNav = UINavigationController()
        let recommendCoordinator = MusicRecommendCoordinator(navigationController: recommendNav)
        childCoordinators.append(recommendCoordinator)
        recommendCoordinator.start()
        
        let reelsNav = UINavigationController()
//        let searchCoordinator = SearchCoordinator(navigationController: searchNav)
//        childCoordinators.append(searchCoordinator)
//        searchCoordinator.start()
        
        let libraryNav = UINavigationController()
//        let favoriteCoordinator = FavoriteCoordinator(navigationController: favoriteNav)
//        childCoordinators.append(favoriteCoordinator)
//        favoriteCoordinator.start()
        
        let userNav = UINavigationController()
//        let userCoordinator = UserCoordinator(navigationController: userNav)
//        childCoordinators.append(userCoordinator)
//        userCoordinator.start()
        
        tabBarController.viewControllers = [recommendNav, reelsNav, libraryNav, userNav]
        navigationController?.pushViewController(tabBarController, animated: false)
    }
}
