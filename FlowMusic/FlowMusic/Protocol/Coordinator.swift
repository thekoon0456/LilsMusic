//
//  Coordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

enum CoordinatorType {
    case app
    case recommend
    case reels
    case library
    case user
    case musicPlayer
    case musicList
}

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController? { get set }
    var type: CoordinatorType { get }
    
    func start()
    func removeChildCoordinator()
}

extension Coordinator {
    
    func start() { }
    
    func removeChildCoordinator() {
        childCoordinators.removeAll()
    }
}
