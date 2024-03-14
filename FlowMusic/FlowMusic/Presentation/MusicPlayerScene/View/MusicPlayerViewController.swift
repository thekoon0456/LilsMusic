//
//  MusicViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//
import MusicKit
import UIKit
import Combine

import Kingfisher
import SnapKit

import RxSwift
import RxCocoa

final class MusicPlayerViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: MusicPlayerViewModel
    
    private let player = MusicPlayerManager.shared
    private let musicRequest = MusicRequest.shared
    private var track: Track
    private var timer: Timer?
    
    private let artistLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.addShadow()
    }
    
    private let songLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.addShadow()
    }
    
    private var artworkImage = UIImageView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray
    }
    
    let pauseImage = UIImage(systemName: "pause")
    
    private lazy var playButton = UIButton().then {
        $0.setImage(pauseImage, for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.setImage(UIImage(systemName: "play.fill"), for: .selected)
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        $0.addShadow()
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        $0.addShadow()
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        $0.addShadow()
    }
    
    private lazy var progressSlider = FMSlider(barHeight: 8).then {
        $0.isContinuous = true
        $0.minimumValue = 0
        $0.setThumbImage(UIImage(), for: .normal)
        $0.setThumbImage(UIImage(), for: .highlighted)
        $0.layer.cornerRadius = 4
        $0.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped))
        $0.addGestureRecognizer(tapGesture)
        $0.addShadow()
    }
    
    private lazy var repeatButton = UIButton().then {
        $0.setImage(UIImage(systemName: "repeat"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(repeatButtonTapped), for: .touchUpInside)
        $0.isSelected = true
        $0.addShadow()
    }
    
    private lazy var shuffleButton = UIButton().then {
        $0.setImage(UIImage(systemName: "shuffle"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(shuffleButtonTapped), for: .touchUpInside)
        $0.isSelected = true
        $0.addShadow()
    }
    
    // MARK: - Lifecycle
    
    init(viewModel: MusicPlayerViewModel, track: Track) {
        self.viewModel = viewModel
        self.track = track
        super.init()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(track)
        updateUI(track)
        //        print(try await player.getCurrentEntry()?.item)
        
        setProgressBarTimer()
        
        setGradient(startColor: track.artwork?.backgroundColor,
                    endColor: track.artwork?.backgroundColor)
        
        player.getCurrentPlayer().queue.objectWillChange.sink { [weak self]  _ in
            guard let self else { return }
            print("노래바뀜")
            Task {
                try await self.updateCurrentEntryUI()
            }
        }.store(in: &cancellables)
    }
    
    func updateUI(_ track: Track) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            artworkImage.kf.setImage(with: track.artwork?.url(width: 500, height: 500))
            artistLabel.text = track.artistName
            songLabel.text = track.title
            //mark 현재 음악 끝 시간 설정
            progressSlider.maximumValue = Float(track.duration ?? 0)
        }
    }
    
    // MARK: - Selectors

    // MARK: - SetProgress
    
    private func setProgressBarTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateProgressBar),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    @objc func updateProgressBar() {
        let value = Float(player.getPlayBackTime())
        progressSlider.setValue(value, animated: false)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        let newValue = sender.value
        player.player.playbackTime = TimeInterval(floatLiteral: Double(newValue))
    }
    
    @objc func sliderTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: progressSlider)
        let sliderWidth = progressSlider.frame.size.width
        let tapValue = tapPoint.x / sliderWidth
        let value = (progressSlider.maximumValue - progressSlider.minimumValue) * Float(tapValue)
        progressSlider.setValue(value, animated: true)
        player.player.playbackTime = TimeInterval(floatLiteral: Double(value))
    }
    
    // MARK: - setStatus
    
    @objc private func repeatButtonTapped() {
        repeatButton.isSelected.toggle()
        
        if repeatButton.isSelected {
            repeatButton.alpha = 1
            player.setRepeatMode(mode: .all)
        } else {
            repeatButton.alpha = 0.5
            player.setRepeatMode(mode: .none)
        }
    }
    
    @objc private func shuffleButtonTapped() {
        shuffleButton.isSelected.toggle()
        shuffleButton.isSelected
        ? (shuffleButton.alpha = 1)
        : (shuffleButton.alpha = 0.5)
        shuffleButton.isSelected
        ? player.setRandomMode(mode: .songs)
        : player.setRandomMode(mode: .off)
    }

    
    @objc private func playButtonTapped() {
        playButton.isSelected.toggle()
        Task {
            do {
                try await playButton.isSelected
                ? player.pause()
                : player.play()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func previousButtonTapped() {
        previousButton.isSelected.toggle()
        Task {
            do {
                try await previousButton.isSelected
                ? player.restart()
                : player.skipToPrevious()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func nextButtonTapped(sender: UIButton) {
        Task {
            try await player.skipToNext()
        }
    }
    
    // MARK: - Helpers
    
    func updateCurrentEntryUI() async throws {
        Task {
            let entry = player.getCurrentEntry()
            guard let song = try await musicRequest.requestSearchSongIDCatalog(id: entry?.item?.id) else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                artworkImage.kf.setImage(with: song.artwork?.url(width: 300, height: 300))
                artistLabel.text =  song.artistName
                songLabel.text = song.title
                // MARK: - 현재 음악 끝 시간 설정
                progressSlider.maximumValue = Float(song.duration ?? 0)
            }
        }
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        view.addSubviews(artworkImage, songLabel, artistLabel, playButton, previousButton, nextButton, progressSlider, shuffleButton, repeatButton)
    }
    
    override func configureLayout() {
        artworkImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(300)
            make.top.equalToSuperview().offset(100)
        }
        
        songLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImage.snp.bottom).offset(20)
            make.width.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(songLabel.snp.bottom).offset(4)
            make.width.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
        
        previousButton.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.centerY.equalTo(playButton.snp.centerY)
            make.trailing.equalTo(playButton.snp.leading).offset(-40)
        }
        
        playButton.snp.makeConstraints { make in
            make.size.equalTo(60)
            make.centerX.equalToSuperview()
            make.top.equalTo(artistLabel.snp.bottom).offset(16)
        }
        
        nextButton.snp.makeConstraints { make in
            make.size.equalTo(32)
            make.centerY.equalTo(playButton.snp.centerY)
            make.leading.equalTo(playButton.snp.trailing).offset(40)
        }
        
        progressSlider.snp.makeConstraints { make in
            make.top.equalTo(playButton.snp.bottom).offset(52)
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(16)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.equalTo(24)
            make.leading.equalTo(progressSlider.snp.leading)
            make.bottom.equalToSuperview().offset(-80)
        }
        
        repeatButton.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.width.equalTo(24)
            make.trailing.equalTo(progressSlider.snp.trailing)
            make.bottom.equalToSuperview().offset(-80)
        }
    }
    
    override func configureView() {
        super.configureView()
        sheetPresentationController?.prefersGrabberVisible = true
    }
}

