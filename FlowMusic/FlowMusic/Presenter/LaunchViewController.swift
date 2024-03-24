//
//  LaunchViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/24/24.
//

import UIKit

import SnapKit

final class LaunchViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let icon = UIImageView().then {
        $0.image = UIImage(systemName: "leaf")
        $0.contentMode = .scaleAspectFill
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.text = "Mint Music"
        $0.textColor = .tintColor
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        view.addSubviews(icon, titleLabel)
    }
    
    // MARK: - Configure
    
    override func configureLayout() {
        super.configureLayout()
        
        icon.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
    }
}
