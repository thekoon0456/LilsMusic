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

    let musicPlayer = MusicPlayer.shared
    private let musicRequest = MusicRequest.shared
    private var musicVideoView = UIView().then {
        $0.backgroundColor = .systemGray
    }
    
    private var player: AVPlayer?
    
    // MARK: - Lifecycles
//    
    override func prepareForReuse() {
        super.prepareForReuse()
        print(#function)
        //cell재사용시 레이아웃 초기화 필요
        musicVideoView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: MusicVideo) {
        print(#function)
        Task {
            DisplayVideoFromUrl(url: data.previewAssets?.first?.hlsURL,
                                view: musicVideoView)
            play()
        }
    }
    
    override func configureHierarchy() {
        contentView.addSubview(musicVideoView)
    }
    
    override func configureLayout() {
        musicVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func DisplayVideoFromUrl(url: URL?, view: UIView) {
        player = AVPlayer(url: url!).then {
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
