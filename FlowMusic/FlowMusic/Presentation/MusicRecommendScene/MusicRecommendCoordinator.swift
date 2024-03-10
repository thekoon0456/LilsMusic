//
//  MusicRecommendCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class MusicRecommendCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .recommend
    }
    
    func start() {
        let vm = MusicRecommendViewModel()
        let vc = MusicRecommendViewController()
        vc.tabBarItem = UITabBarItem(title: <#T##String?#>, image: UIImage(named: FMDesign.Icon.recommend.name), selectedImage: <#T##UIImage?#>)
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
