//
//  ExReels.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/11/24.
//

//import WebKit
//import MusicKit
//import UIKit
//import AVKit
//
//final class ReelsViewController: BaseViewController {
//
//    // MARK: - Properties
//
//    let musicPlayer = MusicPlayer.shared.player
//    private let musicRequest = MusicRequest.shared
//    private let viewModel: ReelsViewModel
//    private let musicVideoView = UIView().then {
//        $0.backgroundColor = .systemGray
//    }
//    var webView = WKWebView()
//
//    var mv: MusicVideo?
////    var url: URL? = URL(string: "https://music.apple.com/kr/music-video/whats-my-name-feat-drake/1445826170?l=en-GB")
//    let apiManager = APIManager.shared
//    // MARK: - Lifecycles
//
//    init(viewModel: ReelsViewModel) {
//        self.viewModel = viewModel
//        super.init()
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        Task {
//            mv = try await musicRequest.requestSearchMusicVideoCatalog(term:"조유리").first
//            print(mv?.url)
//            let url = URL(string: "https://music.apple.com/kr/music-video/taxi/1701968726?l=en-GB")!
//            loadWebView(url: url)
//        }
//
//    }
//
//    override func configureHierarchy() {
//        view.addSubview(webView)
//    }
//
//    override func configureLayout() {
//        webView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//    }
//
//    private func loadWebView(url: URL) {
////        guard let url = URL(string: url!) else { return }
//        let request = URLRequest(url: url)
//
//        webView.load(request)
//    }
//
//    func DisplayVideoFromUrl(url: URL? , myView:UIView) {
//        let player = AVPlayer(url:  URL(string:
//                                            "https://music.apple.com/kr/music-video/whats-my-name-feat-drake/1445826170?l=en-GB")!)
//        let playerLayer = AVPlayerLayer(player: player)
//
//        playerLayer.videoGravity = .resizeAspectFill
//        playerLayer.needsDisplayOnBoundsChange = true
//        playerLayer.frame = myView.bounds
//
//        myView.layer.masksToBounds = true
//        myView.layer.addSublayer(playerLayer)
//        player.play()
//    }
//}
