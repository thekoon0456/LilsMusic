//
//  Coordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

protocol CoordinatorDelegate: AnyObject {
    
    func didFinish(childCoordinator: Coordinator)
}

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
    
    var delegate: CoordinatorDelegate? { get set }
    var navigationController: UINavigationController? { get set }
    var childCoordinators: [Coordinator] { get set }
    var type: CoordinatorType { get }
    
    func start()
    func finish()
    func popViewController()
    func dismissViewController()
    func presentErrorAlert(title: String?, message: String?, handler: (() -> Void)?)
}

extension Coordinator {
    
    func start() { }
    
    func finish() {
        childCoordinators.removeAll()
        delegate?.didFinish(childCoordinator: self)
    }
    
    func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    func dismissViewController() {
        navigationController?.dismiss(animated: true)
    }
    
    func presentErrorAlert(
        title: String? = nil,
        message: String? = "에러 발생",
        handler: (() -> Void)? = nil
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            .appendingAction(title: "확인", handler: handler)
        
        navigationController?.present(alertController, animated: true)
    }
}

// MARK: - SetNavigation

extension Coordinator {
    //투명 네비게이션 바
    func setClearNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        appearance.backgroundColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

// MARK: - Auth

extension Coordinator {
    
    func moveToUserSetting() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Access to Apple Music is required to use the app.",
                                          message: 
                                            "Please allow permission in settings to access the music library.",
                                          preferredStyle: .alert)
            alert.view.tintColor = .label
            
            let primaryButton = UIAlertAction(title: "Go to Settings", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            
            alert.addAction(primaryButton)
            
            navigationController?.present(alert, animated: true)
        }
    }
}
