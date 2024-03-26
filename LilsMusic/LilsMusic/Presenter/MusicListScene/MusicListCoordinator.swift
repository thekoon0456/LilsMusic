//
//  MusicListCoordinator.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit
import MusicKit
import StoreKit

final class MusicListCoordinator: NSObject, Coordinator, CoordinatorDelegate {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController?
    var type: CoordinatorType
    var item: MusicItem //album, playlist
    
    init(navigationController: UINavigationController?, item: MusicItem) {
        self.childCoordinators = []
        self.navigationController = navigationController
        self.type = .musicList
        self.item = item
    }
    
    deinit {
        print("MusicListCoordinator Deinit")
    }
    
    func start() {
        let vm = MusicListViewModel(coordinator: self, item: item)
        
        let vc = MusicListViewController(viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func presentMusicPlayer(track: Track) {
        let coordinator = MusicPlayerCoordinator(navigationController: navigationController,
                                                 track: track)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    func didFinish(childCoordinator: any Coordinator) {
        childCoordinators = []
    }
}

extension MusicListCoordinator: SKCloudServiceSetupViewControllerDelegate {
    //애플뮤직 가입권유화면
    func presentAppleMusicSubscriptionOffer() {
        var options: [SKCloudServiceSetupOptionsKey: Any] = [.action: SKCloudServiceSetupAction.subscribe]
        options[.messageIdentifier] = SKCloudServiceSetupMessageIdentifier.addMusic
        
        let setupViewController = SKCloudServiceSetupViewController()
        setupViewController.delegate = self
        
        setupViewController.load(options: options) { (result, error) in
            if result {
                DispatchQueue.main.async {  [weak self] in
                    guard let self else { return }
                    navigationController?.present(setupViewController, animated: true)
                }
            } else if let error = error {
                print("Error presenting Apple Music subscription offer: \(error.localizedDescription)")
            }
        }
    }
}
