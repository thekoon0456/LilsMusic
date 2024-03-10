//
//  UserCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class UserCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .user
    }
    
    func start() {
        let vm = UserViewModel(coordinator: self)
        let vc = UserViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: nil,
                                     image: UIImage(systemName: FMDesign.Icon.user.name),
                                     selectedImage: UIImage(systemName: FMDesign.Icon.user.fill))
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}
