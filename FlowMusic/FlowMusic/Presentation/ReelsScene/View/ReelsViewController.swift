//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

final class ReelsViewController: BaseViewController {

    // MARK: - Properties

    let musicPlayer = MusicPlayer.shared.player
    private let musicRequest = MusicRequest.shared
    private let viewModel: ReelsViewModel
    
    // MARK: - Lifecycles

    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func configureHierarchy() {
    }

    override func configureLayout() {
    }
}

























