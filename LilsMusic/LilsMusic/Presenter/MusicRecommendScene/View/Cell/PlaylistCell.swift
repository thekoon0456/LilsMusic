//
//  PlaylistCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/15/24.
//

import Foundation

import UIKit
import MusicKit

import Kingfisher
import SnapKit

final class PlaylistCell: BaseCollectionViewCell {
    
    private let backView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let artworkImageView = UIImageView()
    
    private let infoBGView = UIView().then {
        $0.backgroundColor = .systemGray6
    }
    
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textAlignment = .center
    }
    
    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    func configureCell(_ data: Playlist) {
        artworkImageView.kf.setImage(with: data.artwork?.url(width: 400, height: 400))
        nameLabel.text = data.name
        descriptionLabel.text = data.shortDescription
    }
    
    override func configureHierarchy() {
        contentView.addSubview(backView)
        backView.addSubviews(artworkImageView, infoBGView, nameLabel, descriptionLabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(contentView.snp.width)
        }
        
        infoBGView.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(infoBGView.snp.top).offset(4)
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.bottom.equalTo(descriptionLabel.snp.top).offset(-4)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.bottom.lessThanOrEqualToSuperview().offset(-4)
        }
    }
    
    override func configureView() {
        super.configureView()
//        addShadow()
    }
}
