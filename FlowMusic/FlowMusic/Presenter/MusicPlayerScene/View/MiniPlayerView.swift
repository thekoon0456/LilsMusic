//
//  MiniPlayerView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/16/24.
//

import UIKit
import MusicKit

import Kingfisher

final class MiniPlayerView: BaseView {
    
    // MARK: - Properties
    
    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 16)
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
    }
    
    private lazy var playButton = UIButton().then {
        $0.setImage(UIImage(systemName: "pause"), for: .normal)
        $0.setImage(UIImage(systemName: "play.fill"), for: .selected)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
    }
    
    // MARK: - Helpers
    
    func configureView(_ data: Track) {
        iconImageView.kf.setImage(with: data.artwork?.url(width: 40, height: 40))
        titleLabel.text = data.title
        subtitleLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        addSubviews(iconImageView, titleLabel, subtitleLabel, previousButton, playButton, nextButton)
    }
    
    override func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.top)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.greaterThanOrEqualTo(previousButton.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.bottom.equalTo(iconImageView.snp.bottom)
        }
        
        previousButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(playButton.snp.leading).offset(-20)
        }
        
        playButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(nextButton.snp.leading).offset(-20)
        }
        
        nextButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    override func configureView() {
        super.configureView()
        addShadow()
        backgroundColor = .systemBackground
        layer.cornerRadius = 20
        alpha = 0.95
    }
}

