//
//  ReelsCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class ReelsCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .reels
        setClearNavigationBar()
    }
    
    func start() {
        let vm = ReelsViewModel(coordinator: self)
        let vc = ReelsViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: nil,
                                     image: UIImage(systemName: FMDesign.Icon.reels.name),
                                     selectedImage: UIImage(systemName: FMDesign.Icon.reels.fill))
        navigationController?.pushViewController(vc, animated: false)
    }
}
