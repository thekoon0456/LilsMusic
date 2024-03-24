//
//  LibraryCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import MusicKit
import UIKit

import CollectionViewPagingLayout

final class LibraryCell: BaseCollectionViewCell {
    
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
    
    // MARK: - Lifecycles
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func configureCell(_ playlist: Playlist) {
        artworkImageView.kf.setImage(with: playlist.artwork?.url(width: 400, height: 400))
        nameLabel.text = playlist.name
        descriptionLabel.text = playlist.curatorName
    }
    
    override func configureHierarchy() {
        contentView.addSubview(backView)
        backView.addSubviews(artworkImageView, infoBGView, nameLabel, descriptionLabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.size.equalTo(260)
            make.center.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        infoBGView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(descriptionLabel.snp.top).offset(-4)
            make.height.equalTo(22)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(14)
        }
    }
    
    override func configureView() {
        super.configureView()
    }
}

extension LibraryCell: ScaleTransformView {
    
    var scaleOptions: ScaleTransformViewOptions {
        return .layout(.coverFlow)
    }
}
