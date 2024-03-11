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
    
    let musicPlayer = MusicPlayer.shared.player
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
            guard let video = try await musicRequest.requestSearchMusicVideoCatalog(term: "조유리").first else { return }
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
            print(video.songs)
            print(video.url)
            print(video.id)
            print(video.id)
            print(video.id)
            print(video.id)
            
            guard let url = video.url?.absoluteURL else { return }
            print(url)
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
        let player = AVPlayer(url: url!)
        let playerLayer = AVPlayerLayer(player: player)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.frame = view.bounds
        
        view.layer.masksToBounds = true
        view.layer.addSublayer(playerLayer)
        player.play()
    }
}

























