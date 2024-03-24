//
//  AppCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit
import StoreKit

final class AppCoordinator: NSObject, Coordinator {

    // MARK: - Properties
    
    weak var delegate: CoordinatorDelegate?
    var navigationController: UINavigationController?
    var childCoordinators: [Coordinator]
    var type: CoordinatorType
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.childCoordinators = []
        self.type = .app
    }
    
    // MARK: - Helpers
    
    func start() {
        //TODO: - 온보딩 분기처리
        presentLaunch()
        requestMusicAuthorization()
//        makeTabbar()
    }
    
    func makeTabbar() {
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
        
//        let userNav = UINavigationController()
//        let userCoordinator = UserCoordinator(navigationController: userNav)
//        childCoordinators.append(userCoordinator)
//        userCoordinator.start()
        
//        tabBarController.viewControllers = [recommendNav, reelsNav, libraryNav, userNav]
        
        tabBarController.viewControllers = [recommendNav, reelsNav, libraryNav]
        navigationController?.pushViewController(tabBarController, animated: false)
    }
    
    func presentLaunch() {
        let vc = LaunchViewController()
        navigationController?.pushViewController(vc, animated: false)
    }
    
}

extension AppCoordinator: SKCloudServiceSetupViewControllerDelegate {
    
    func requestMusicAuthorization() {
        SKCloudServiceController.requestAuthorization { [weak self] status in
            guard let self else { return }
            switch status {
            case .authorized:
                print("승인됨")
                makeTabbar()
                break
            default:
                moveToUserSetting()
                break
            }
        }
    }
    
//    func requestMusicAuthorization() async throws {
//        let status = await MusicAuthorization.request()
//        switch status {
//        case .authorized:
//            print("승인됨")
//        default:
//            moveToUserSetting()
//            print("승인안됨. 재요청")
//        }
//    }
}
