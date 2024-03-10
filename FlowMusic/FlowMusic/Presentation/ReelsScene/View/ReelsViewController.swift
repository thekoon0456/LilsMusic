//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import UIKit

final class ReelsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: ReelsViewModel
    
    // MARK: - Lifecycles
    
    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
}
