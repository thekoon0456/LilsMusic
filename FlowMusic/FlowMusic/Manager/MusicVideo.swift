//
//  MusicVideo.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/11/24.
//

import AVKit
import MusicKit
import UIKit

final class MusicVideoView: UIView {
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    var videoURL: URL? {
        didSet {
            setupPlayer()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayer()
    }
    
    private func setupPlayer() {
        guard let videoURL = videoURL else {
            return
        }
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        layer.addSublayer(playerLayer!)
        
        player?.play()
    }
}
