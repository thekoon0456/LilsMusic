//
//  MusicChartsCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

import Kingfisher
import SnapKit

final class MusicChartsCell: BaseCollectionViewCell {
    
    private let artworkImageView = UIImageView()
    
    func configureCell(_ data: Playlist) {
        artworkImageView.kf.setImage(with: data.artwork?.url(width: 400, height: 400))
    }
    
    override func configureHierarchy() {
        contentView.addSubview(artworkImageView)
    }
    
    override func configureLayout() {
        artworkImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        layer.cornerRadius = 10
        clipsToBounds = true
    }
}
