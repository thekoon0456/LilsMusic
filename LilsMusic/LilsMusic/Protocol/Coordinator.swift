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
            let alert = UIAlertController(title: "음악 접근 권한이 필요합니다.",
                                          message: "음악 라이브러리에 접근하기 위해서는 설정에서 권한을 허용해주세요",
                                          preferredStyle: .alert)
            
            let primaryButton = UIAlertAction(title: "설정으로 가기", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            let cancelButton = UIAlertAction(title: "취소", style: .default)
            
            alert.addAction(primaryButton)
            alert.addAction(cancelButton)
            
            navigationController?.present(alert, animated: true)
        }
    }
}
