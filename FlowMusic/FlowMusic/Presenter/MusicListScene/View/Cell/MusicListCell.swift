//
//  MusicListCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

import Kingfisher
import MarqueeLabel

final class MusicListCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }
    
    private let titleLabel = MarqueeLabel().then {
        $0.font = .systemFont(ofSize: 18)
        $0.type = .continuous
        $0.animationCurve = .easeInOut
        $0.trailingBuffer = 60
        $0.speed = .duration(17)
    }
    
    private let subtitleLabel = MarqueeLabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.type = .continuous
        $0.animationCurve = .easeInOut
        $0.trailingBuffer = 60
        $0.speed = .duration(17)
    }
    
    // MARK: - Lifecycles
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = UIImage()
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: Track) {
        iconImageView.kf.setImage(with: data.artwork?.url(width: 100, height: 100))
        titleLabel.text = data.title
        subtitleLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        super.configureHierarchy()
        contentView.addSubviews(iconImageView,
                                titleLabel,
                                subtitleLabel)
    }
    
    override func configureLayout() {
        super.configureLayout()
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalTo(iconImageView.snp.bottom)
        }
    }
    
    override func configureView() {
        super.configureView()
        backgroundColor = .clear
    }
}
