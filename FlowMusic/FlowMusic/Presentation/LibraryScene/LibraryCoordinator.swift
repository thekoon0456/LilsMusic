//
//  LibraryCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class LibraryCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    
    init(navigationController: UINavigationController?) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .library
    }
    
    func start() {
        let vm = LibraryViewModel(coordinator: self)
        let vc = LibraryViewController(viewModel: vm)
        vc.tabBarItem = UITabBarItem(title: nil,
                                     image: UIImage(systemName: FMDesign.Icon.library.name),
                                     selectedImage: UIImage(systemName: FMDesign.Icon.library.fill))
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func pushToList(album: Album) {
        let coorinator = MusicListCoordinator(navigationController: navigationController,
                                              album: album)
        coorinator.start()
    }
    
    
}
