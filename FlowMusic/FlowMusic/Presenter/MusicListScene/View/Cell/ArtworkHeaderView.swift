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
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).then {
        $0.alpha = 0.3
    }
    
    private let artworkImageView = UIImageView()
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .bgColor
        $0.textAlignment = .left
    }
    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
        $0.textAlignment = .left
    }
    
    lazy var playButton = UIButton().then {
        let image = UIImage(systemName: "play.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 40)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    lazy var shuffleButton = UIButton().then {
        let image = UIImage(systemName: "shuffle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
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
        addSubviews(blurView, artworkImageView, titleLabel, descriptionLabel, playButton, shuffleButton)
        
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        artworkImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(artworkImageView.snp.width)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(shuffleButton.snp.leading).offset(-8)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalTo(shuffleButton.snp.leading).offset(-8)
            make.bottom.equalToSuperview().offset(-12)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.trailing.equalTo(playButton.snp.leading).offset(-20)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(shuffleButton.snp.height)
        }
        
        playButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.top)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-12)
            make.width.equalTo(playButton.snp.height)
        }
    }
    
    func updateUI(_ item: MusicItem) {
        switch item {
        case let playlist as Playlist:
            artworkImageView.kf.setImage(with: playlist.artwork?.url(width: 800, height: 800))
            setGradient(startColor: playlist.artwork?.backgroundColor,
                        endColor: playlist.artwork?.backgroundColor)
            titleLabel.text = playlist.name
            descriptionLabel.text = playlist.curatorName
        case let album as Album:
            artworkImageView.kf.setImage(with: album.artwork?.url(width: 800, height: 800))
            setGradient(startColor: album.artwork?.backgroundColor,
                        endColor: album.artwork?.backgroundColor)
            titleLabel.text = album.title
            descriptionLabel.text = album.artistName
        case let track as Track:
            artworkImageView.kf.setImage(with: track.artwork?.url(width: 800, height: 800))
            setGradient(startColor: track.artwork?.backgroundColor,
                        endColor: track.artwork?.backgroundColor)
            titleLabel.text = track.title
            descriptionLabel.text = track.artistName
        default:
            return
        }
    }
}
