//
//  AlbumArtCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import MusicKit
import UIKit

import Kingfisher
import SnapKit

final class AlbumArtCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    private let backView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let artworkImageView = UIImageView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textAlignment = .center
    }
    
    private let artistLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: Album) {
        artworkImageView.kf.setImage(with: data.artwork?.url(width: 200, height: 200))
        titleLabel.text = data.title
        artistLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        contentView.addSubview(backView)
        backView.addSubviews(artworkImageView, titleLabel, artistLabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(contentView.snp.width)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.bottom.equalTo(artistLabel.snp.top).offset(-4)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(-4)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        backView.addShadow()
    }
}
