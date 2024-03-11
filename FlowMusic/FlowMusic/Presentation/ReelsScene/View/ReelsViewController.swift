//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit
import AVFoundation
import AVKit

import SnapKit

final class ReelsViewController: BaseViewController {
    
    // MARK: - Properties
    
    let musicPlayer = MusicPlayer.shared
    private let musicRequest = MusicRequest.shared
    private let viewModel: ReelsViewModel
    private let musicVideoView = UIView().then {
        $0.backgroundColor = .systemGray
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            guard let video1 = try await musicRequest.requestSearchMusicVideoCatalog(term: "이세계아이돌").first else { return }
            let video = try await video1.with(.songs, preferredSource: .catalog)
            let response = try await musicRequest.requestSearchMVIDCatalog(id: video.id)
            let song = try await musicRequest.requestSearchSongCatalog(term: "\(video.artistName) \(video.title)")
            musicPlayer.setSongQueue(song: song[0])
            print(song[0])
            try await musicPlayer.play()
            print(song)
            print(response)
            print(video)
            print(video.albumTitle)
            print(video.albums)
            print(video.artistName)
            print(video.artistURL)
            print(video.moreByArtist)
            print(video.contentRating)
            print(video.debugDescription)
            print(video.description)
            print(video.duration)
            print(video.has4K)
            print(video.hasHDR)
            print(video.id)
            print(video.isrc)
            print(video.playParameters)
            print(video.previewAssets)
            print(video.songs?.first)
            print(video.url)
            DisplayVideoFromUrl(url: video.previewAssets?.first?.hlsURL, view: musicVideoView)
        }
    }
    
    override func configureHierarchy() {
        view.addSubview(musicVideoView)
    }
    
    override func configureLayout() {
        musicVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func DisplayVideoFromUrl(url: URL?, view: UIView) {
        configureAudioSession()
        let player = AVPlayer(url: url!)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.frame = view.bounds
        
        view.layer.masksToBounds = true
        view.layer.addSublayer(playerLayer)
        player.play()
        player.isMuted = true
    }
    
    func configureAudioSession() {
        do {
            // 오디오 세션 인스턴스 가져오기
            let audioSession = AVAudioSession.sharedInstance()
            
            // 오디오 세션 카테고리 설정. 이 경우, 다른 앱의 오디오와 함께 재생될 수 있도록 함
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            
            // 오디오 세션 활성화
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
}

























