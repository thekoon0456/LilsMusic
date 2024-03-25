//
//  ReelsCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import AVFoundation
import AVKit
import MusicKit
import UIKit

import RxCocoa
import RxSwift
import SnapKit

final class ReelsCell: BaseCollectionViewCell {
    
    // MARK: - Properties
    
    private let viewModel: ReelsCellViewModel = ReelsCellViewModel()
    private let mvSubject = BehaviorSubject<MusicVideo?>(value: nil)
    
    // MARK: - UI
    
    private let indicatorView = UIActivityIndicatorView(style: .medium)
    
    var musicVideoView = UIView().then {
        $0.backgroundColor = .lightGray
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
        heartButton.isSelected = false
        disposeBag = DisposeBag()
    }
    
    // MARK: - Bind
    
    override func bind() {
        super.bind()
        
        let heartButtonTapped = heartButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> Bool in
                guard let self else { return false }
                return heartButton.isSelected
            }
        
        let input = ReelsCellViewModel.Input(mv: mvSubject.asObservable(),
                                             heartButtonTapped: heartButtonTapped)
        
        let output = viewModel.transform(input)
        
        output.isHeart.drive(with: self) { owner, bool in
            owner.heartButton.isSelected = bool
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Helpers
    
    func configureCell(_ data: MusicVideo) {
        //cell재사용할때 bind
        bind()
        mvSubject.onNext(data)

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
        contentView.addSubviews(musicVideoView, indicatorView, musicLabel, artistLabel,
                                genreLabel, heartButton)
    }
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    override func configureView() {
        super.configureView()
    }
    
    func DisplayVideoFromAssets(asset: AVURLAsset, view: UIView) {
        startLoadingIndicator()
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    stopLoadingIndicator()
                    player?.play()
                case .failed, .unknown:
                    print("Failed to load the video")
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Indicator

extension ReelsCell {
    
    func startLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            indicatorView.startAnimating()
        }

    }

    func stopLoadingIndicator() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            indicatorView.stopAnimating()
        }
    }
}

// MARK: - Play

extension ReelsCell {
    
    func play() {
        player?.play()
    }
    
    func mute() {
        player?.isMuted = true
    }
    
    func soundOn() {
        player?.isMuted = false
    }
    
    func pause() {
        NotificationCenter.default.removeObserver(self)
        player?.pause()
    }
}

extension ReelsCell {
    
    private func setLayout() {
        musicVideoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        indicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
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

////스켈레톤 애니메이션
//extension UIView {
//
//    func addShimmerEffect(duration: CFTimeInterval = 2.0, bounce: Bool = false, delay: CFTimeInterval = 0) {
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [
//            UIColor.clear.cgColor,
//            UIColor.white.withAlphaComponent(0.75).cgColor,
//            UIColor.clear.cgColor
//        ]
//        gradientLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 2, height: bounds.height)
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
//        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
//        gradientLayer.locations = [0.0, 0.5, 1.0]
//        
//        let animation = CABasicAnimation(keyPath: "locations")
//        animation.fromValue = [0.0, 0.0, 0.25]
//        animation.toValue = [0.75, 1.0, 1.0]
//        animation.duration = duration
//        animation.repeatCount = bounce ? .greatestFiniteMagnitude : .infinity
//        animation.isRemovedOnCompletion = false
//        animation.fillMode = .forwards
//        animation.beginTime = CACurrentMediaTime() + delay
//        gradientLayer.add(animation, forKey: "shimmer")
//
//        layer.mask = gradientLayer
//    }
//
//    func removeShimmerEffect() {
//        layer.mask = nil
//    }
//}
