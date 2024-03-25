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
    
    let iconView = UIImageView().then {
        $0.image = UIImage(named: "lil")
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 24)
        $0.text = "Lils Music"
        $0.textColor = .tintColor
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        view.addSubviews(iconView, titleLabel)
    }
    
    // MARK: - Configure
    
    override func configureLayout() {
        super.configureLayout()
        
        iconView.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
    }
}
