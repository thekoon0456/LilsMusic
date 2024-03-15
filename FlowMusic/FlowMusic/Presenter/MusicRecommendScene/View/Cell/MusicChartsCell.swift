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
    
    private let backView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let artworkImageView = UIImageView()
    
    private let infoBGView = UIView().then {
        $0.backgroundColor = .systemGray6
    }
    
    private let albumlabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textAlignment = .center
    }
    
    private let artistlabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    func configureCell(_ data: Song) {
        artworkImageView.kf.setImage(with: data.artwork?.url(width: 200, height: 200))
        albumlabel.text = data.title
        artistlabel.text = data.artistName
    }
    
    override func configureHierarchy() {
        contentView.addSubview(backView)
        backView.addSubviews(artworkImageView, infoBGView, albumlabel, artistlabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        infoBGView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(40)
        }
        
        albumlabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(artistlabel.snp.top).offset(-4)
        }
        
        artistlabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().offset(-4)
        }
    }
    
    override func configureView() {
        super.configureView()
        layer.masksToBounds = false
        layer.shadowOpacity = 0.8
        layer.shadowOffset = .init(width: 0, height: 0)
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowRadius = 5
    }
}
