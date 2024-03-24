//
//  ReelsCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit
import AVFoundation
import AVKit

import SnapKit

final class ReelsCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    let viewModel: ReelsCellViewModel = ReelsCellViewModel()
    
    // MARK: - UI
    
    var musicVideoView = UIView().then {
        $0.backgroundColor = .tertiarySystemBackground
    }
    
    private let musicLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 28)
        $0.textColor = .white
    }
    
    private let artistLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .white
    }
    
    private let genreLabel = PaddingLabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .label
        $0.backgroundColor = .tertiarySystemGroupedBackground
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }
    
    private lazy var heartButton = UIButton().then {
        let image = UIImage(systemName: FMDesign.Icon.heart.name)?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 28)))
        let fillImage = UIImage(systemName: FMDesign.Icon.heart.fill)?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 28)))
        $0.setImage(image, for: .normal)
        $0.setImage(fillImage, for: .selected)
        $0.contentVerticalAlignment = .bottom
        $0.contentHorizontalAlignment = .trailing
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
//    private let addToPlaylistButton = UIButton().then {
//        $0.setImage(UIImage(systemName: "list.bullet.rectangle.portrait"), for: .normal)
//    }
    
    private var player: AVPlayer?
    
    // MARK: - Lifecycles
    //
    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        musicVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: MusicVideo) {
        print(#function)
        
        guard let url = data.previewAssets?.first?.hlsURL else { return }
        let asset = AVURLAsset(url: url)
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            DisplayVideoFromAssets(asset: asset, view: musicVideoView)
            play()
        }
        
        musicLabel.text = data.title
        artistLabel.text = data.artistName
        genreLabel.text = data.genreNames.first
    }
    
    override func configureHierarchy() {
        super.configureHierarchy()
        contentView.addSubviews(musicVideoView, musicLabel, artistLabel,
                                genreLabel, heartButton)
    }
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    func DisplayVideoFromAssets(asset: AVURLAsset, view: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem).then {
            $0.isMuted = true
        }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.frame = view.bounds
        view.layer.masksToBounds = true
        view.layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
            guard let self else { return }
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Play

extension ReelsCell {
    
    func play() {
        print(#function)
        player?.play()
    }
    
    func mute() {
        print(#function)
        player?.isMuted = true
    }
    
    func soundOn() {
        print(#function)
        player?.isMuted = false
    }
    
    func pause() {
        print(#function)
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

extension ReelsCell {
    
    private func setLayout() {
        musicVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        musicLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(artistLabel.snp.top).offset(-8)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(genreLabel.snp.top).offset(-12)
        }
        
        genreLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-28)
        }
        
        heartButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-28)
        }
    }
}
