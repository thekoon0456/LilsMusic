//
//  AppDelegate.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        let mvRepo = MVRepository.shared
        Task {
            try await mvRepo.fetchTodayMVURL(index: 0)
            mvRepo.downloadInitialVideos(videoURLs: mvRepo.videoURLs)
            print(mvRepo.cachedVideoURLs.count)
        }

        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }
}
