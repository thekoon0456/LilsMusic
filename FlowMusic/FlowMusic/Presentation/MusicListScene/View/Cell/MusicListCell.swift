//
//  MusicListCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

import Kingfisher

final class MusicListCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18)
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: Track) {
        iconImageView.kf.setImage(with: data.artwork?.url(width: 40, height: 40))
        titleLabel.text = data.title
        subtitleLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        contentView.addSubviews(iconImageView,
                                titleLabel,
                                subtitleLabel)
    }
    
    override func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().offset(-8)
        }
    }
}
