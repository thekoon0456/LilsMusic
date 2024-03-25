//
//  ArtistCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import MusicKit
import UIKit

import Kingfisher
import SnapKit

final class ArtistCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    private let backView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private lazy var artworkImageView = UIImageView().then {
        $0.layer.cornerRadius = frame.width / 2
        $0.clipsToBounds = true
    }
    
    private let artistLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textAlignment = .center
    }
    
    private let genrelabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: Artist) {
        artworkImageView.kf.setImage(with: data.artwork?.url(width: 200, height: 200))
        artistLabel.text = data.name
        genrelabel.text = data.genres?.map { $0.name }.joined(separator: ", ")
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        contentView.addSubview(backView)
        backView.addSubviews(artworkImageView, artistLabel, genrelabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(contentView.snp.width)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().offset(-8)
            make.bottom.equalTo(artistLabel.snp.top).offset(-4)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    override func configureView() {
        super.configureView()
//        addShadow()
    }
}
