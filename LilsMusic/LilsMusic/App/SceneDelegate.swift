//
//  SceneDelegate.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        window?.makeKeyAndVisible()
        window?.tintColor = .tintColor
        let nav = UINavigationController()
        nav.isNavigationBarHidden = true
        
        appCoordinator = AppCoordinator(navigationController: nav)
        appCoordinator?.start()
        window?.rootViewController = nav
    }

    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) {
        SubscriptionManager.shared.checkAppleMusicSubscriptionEligibility { bool in
            print("유저 구독\(bool)")
            UserDefaultsManager.shared.userSubscription.isSubscribe = bool
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) { }
}
