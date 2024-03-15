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
    
    let musicPlayer = MusicPlayerManager.shared
    private let musicRequest = MusicRequest.shared
    
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
    
    private let addToPlaylistButton = UIButton().then {
        $0.setImage(UIImage(systemName: "list.bullet.rectangle.portrait"), for: .normal)
    }
    
    private var player: AVPlayer?
    
    // MARK: - Lifecycles
    //
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#function)
        player?.pause()
        NotificationCenter.default.removeObserver(self)
        //cell 재사용시 뮤비 플레이어 레이아웃 초기화 필요
        musicVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
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
        
//        DispatchQueue.main.async { [weak self] in
//            guard let self else { return }
//            DisplayVideoFromUrl(url: <#T##URL?#>, view: <#T##UIView#>)
//        }
        musicLabel.text = data.title
        artistLabel.text = data.artistName
        genreLabel.text = data.genreNames.first
        
        Task {
            //뮤비의 song타입
            let result = try await musicRequest.MusicVideoToSong(data)
            
        }
    }
    
    override func configureHierarchy() {
        contentView.addSubviews(musicVideoView, musicLabel, artistLabel, genreLabel)
    }
    
    override func configureLayout() {
        musicVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        musicLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(artistLabel.snp.top).offset(-4)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-60)
        }
        
        genreLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide).offset(-30)
        }
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

//    func DisplayVideoFromUrl(url: URL?, view: UIView) {
//        guard let url else { return }
//        player = AVPlayer(url: url).then {
//            $0.isMuted = true
//        }
//        print(url)
//        let playerLayer = AVPlayerLayer(player: player)
//        playerLayer.videoGravity = .resizeAspectFill
//        playerLayer.needsDisplayOnBoundsChange = true
//        playerLayer.frame = view.bounds
//        view.layer.masksToBounds = true
//        view.layer.addSublayer(playerLayer)
//
//        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
//                                               object: player?.currentItem,
//                                               queue: .main) { [weak self] _ in
//            guard let self else { return }
//            player?.seek(to: .zero)
//            player?.play()
//        }
//    }

//
//func configureCell(_ data: MusicVideo) {
//    Task {
//        guard let video1 = try await musicRequest.requestSearchMusicVideoCatalog(term: "이세계아이돌").first else { return }
//        let video = try await video1.with(.songs, preferredSource: .catalog)
//        let response = try await musicRequest.requestSearchMVIDCatalog(id: data.id)
//        let song = try await musicRequest.requestSearchSongCatalog(term: "\(data.artistName) \(data.title)")
//        musicPlayer.setSongQueue(song: song[0])
//        print(song[0])
//        try await musicPlayer.play()
//        print(data.previewAssets?.first?.hlsURL)
//        DisplayVideoFromUrl(url: data.previewAssets?.first?.hlsURL, view: musicVideoView)
//    }
//}
//func configureAudioSession() {
//    do {
//        // 오디오 세션 인스턴스 가져오기
//        let audioSession = AVAudioSession.sharedInstance()
//        // 오디오 세션 카테고리 설정. 이 경우, 다른 앱의 오디오와 함께 재생될 수 있도록 함
//        try audioSession.setCategory(.playback,
//                                     mode: .default,
//                                     options: [.mixWithOthers])
//        // 오디오 세션 활성화
//        try audioSession.setActive(true)
//    } catch {
//        print("Failed to configure audio session: \(error.localizedDescription)")
//    }
//}
