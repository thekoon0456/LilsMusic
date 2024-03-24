//
//  ArtworkHeaderView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/17/24.
//

import MusicKit
import UIKit

import SnapKit
import Kingfisher

final class ArtworkHeaderReusableView: UICollectionReusableView {
    
    // MARK: - Properties
    
    static var identifier: String {
        return self.description()
    }
    
    private let artworkImageView = UIImageView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
    private let artistLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    lazy var playButton = UIButton().then {
        $0.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
//        $0.layer.borderColor = UIColor.tintColor.cgColor
//        $0.layer.borderWidth = 1
//        $0.layer.cornerRadius = 16
//        $0.clipsToBounds = true
        $0.tintColor = .tintColor
//        $0.addShadow()
    }
    
    lazy var shuffleButton = UIButton().then {
        $0.setImage(UIImage(systemName: "shuffle"), for: .normal)
        $0.layer.borderColor = FMDesign.Color.tintColor.color.cgColor
        $0.layer.borderWidth = 1
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.tintColor = .tintColor
//        $0.addShadow()
    }
    
    // MARK: - Lifecycles
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure
    
    private func setupLayout() {
        addSubviews(artworkImageView, titleLabel, artistLabel, playButton, shuffleButton)
        
        artworkImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(200)
            make.bottom.equalTo(titleLabel.snp.top).offset(-20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(artistLabel.snp.top).offset(-8)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(playButton.snp.top).offset(-20)
        }
        
        playButton.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.centerX.equalToSuperview().offset(-(frame.width / 4))
            make.top.equalTo(artistLabel.snp.bottom).offset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(40)
            make.centerX.equalToSuperview().offset(frame.width / 4)
            make.top.equalTo(artistLabel.snp.bottom).offset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
    }
    
    func updateUI(_ item: MusicItem) {
        switch item {
        case let playlist as Playlist:
            artworkImageView.kf.setImage(with: playlist.artwork?.url(width: 300, height: 300))
            setGradient(startColor: playlist.artwork?.backgroundColor,
                        endColor: playlist.artwork?.backgroundColor)
            titleLabel.text = playlist.name
            artistLabel.text = playlist.shortDescription
        case let album as Album:
            artworkImageView.kf.setImage(with: album.artwork?.url(width: 300, height: 300))
            setGradient(startColor: album.artwork?.backgroundColor,
                        endColor: album.artwork?.backgroundColor)
            titleLabel.text = album.title
            artistLabel.text = album.artistName
        case let track as Track:
            artworkImageView.kf.setImage(with: track.artwork?.url(width: 300, height: 300))
            setGradient(startColor: track.artwork?.backgroundColor,
                        endColor: track.artwork?.backgroundColor)
            titleLabel.text = track.title
            artistLabel.text = track.artistName
        default:
            return
        }
    }
}
