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
        $0.setImage(UIImage(systemName: "play.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .systemGreen
        $0.addShadow()
    }
    
    lazy var shuffleButton = UIButton().then {
        $0.setImage(UIImage(systemName: "shuffle"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .systemGreen
        $0.addShadow()
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
        addSubviews(artworkImageView, titleLabel, artistLabel)
        
        artworkImageView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(200)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
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
        default:
            return
        }
    }
}

extension ArtworkHeaderReusableView {
    
    func setGradient(startColor: CGColor?, endColor: CGColor?) {
        let gradientLayer = CAGradientLayer()
        let startColor = startColor?.copy(alpha: 1.0) ?? CGColor(gray: 0, alpha: 0)
        let endColor = endColor?.copy(alpha: 0.5) ?? CGColor(gray: 0, alpha: 0)
        gradientLayer.frame = bounds
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        //기존에 추가된 레이어 삭제
        layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
