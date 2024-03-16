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

import RxCocoa
import RxSwift


final class MusicPlayerViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: MusicPlayerViewModel
    private var timer: Timer?
    
    // MARK: - UI
    
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
    
    private lazy var playButton = UIButton().then {
        $0.setImage(UIImage(systemName: "pause"), for: .normal)
        $0.setImage(UIImage(systemName: "play.fill"), for: .selected)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
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
        $0.tintColor = .systemGreen
        $0.addShadow()
    }
    
    private lazy var shuffleButton = UIButton().then {
        $0.setImage(UIImage(systemName: "shuffle"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .systemGreen
        $0.addShadow()
    }
    
    // MARK: - Lifecycle
    
    init(viewModel: MusicPlayerViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProgressBarTimer()
        setDismissGesture()
    }
    
    // MARK: - Bind
    
    override func bind() {
        super.bind()
        
        let playButtonTapped = playButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak playButton] in
            return playButton?.isSelected ?? true
        }
        
        let repeatButtonTapped = repeatButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak repeatButton] in
            return repeatButton?.isSelected ?? true
        }
        
        let shuffleButtonTapped = shuffleButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak shuffleButton] in
            return shuffleButton?.isSelected ?? true
        }
        
        let input = MusicPlayerViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in },
                                               playButtonTapped: playButtonTapped,
                                               previousButtonTapped: previousButton.rx.tap,
                                               nextButtonTapped: nextButton.rx.tap,
                                               repeatButtonTapped: repeatButtonTapped,
                                               shuffleButtonTapped: shuffleButtonTapped,
                                               viewWillDisappear: self.rx.viewWillDisappear.map { _ in })
        let output = viewModel.transform(input)
        
        output.updateEntry.drive(with: self) { owner, track in
            guard let track else { return }
            owner.updateUI(track)
        }.disposed(by: disposeBag)
        
        output.playState.drive(with: self) { owner, bool in
            owner.playButton.isSelected.toggle()
        }.disposed(by: disposeBag)
        
        output.repeatMode.drive(with: self) { owner, bool in
            owner.repeatButton.isSelected = bool
            owner.setButtonAlpha()
        }.disposed(by: disposeBag)
        
        output.shuffleMode.drive(with: self) { owner, bool in
            owner.shuffleButton.isSelected = bool
            owner.setButtonAlpha()
        }.disposed(by: disposeBag)
    }
    
    @objc func updateProgressBar() {
        let value = Float(viewModel.musicPlayer.getPlayBackTime())
        progressSlider.setValue(value, animated: false)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        let newValue = sender.value
        viewModel.musicPlayer.setPlayBackTime(value: Double(newValue))
    }
    
    @objc func sliderTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: progressSlider)
        let sliderWidth = progressSlider.frame.size.width
        let tapValue = tapPoint.x / sliderWidth
        let value = (progressSlider.maximumValue - progressSlider.minimumValue) * Float(tapValue)
        progressSlider.setValue(value, animated: true)
        viewModel.musicPlayer.setPlayBackTime(value: Double(value))
    }
    
    // MARK: - UI
    
    func updateUI(_ track: Track) {
        artworkImage.kf.setImage(with: track.artwork?.url(width: 500, height: 500))
        artistLabel.text = track.artistName
        songLabel.text = track.title
        repeatButton.isSelected = UserDefaultsManager.shared.isRepeat
        shuffleButton.isSelected = UserDefaultsManager.shared.isShuffle
        //백그라운드
        setGradient(startColor: track.artwork?.backgroundColor,
                    endColor: track.artwork?.backgroundColor)
        //현재 음악 끝 시간 설정
        progressSlider.maximumValue = Float(track.duration ?? 0)
    }
    
    func setButtonAlpha() {
        let isRepeat = UserDefaultsManager.shared.isRepeat
        isRepeat
        ? (repeatButton.alpha = 1)
        : (repeatButton.alpha = 0.3)
        let isShuffle = UserDefaultsManager.shared.isShuffle
        isShuffle
        ? (shuffleButton.alpha = 1)
        : (shuffleButton.alpha = 0.3)
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        super.configureHierarchy()
        view.addSubviews(artworkImage, songLabel, artistLabel, playButton,
                         previousButton, nextButton, progressSlider, shuffleButton, repeatButton)
    }
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    override func configureView() {
        super.configureView()
        sheetPresentationController?.prefersGrabberVisible = true
    }
}

// MARK: - ProgressBar

extension MusicPlayerViewController {
    
    private func setProgressBarTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateProgressBar),
                                     userInfo: nil,
                                     repeats: true)
    }
}

// MARK: - Configure

extension MusicPlayerViewController {
    
    func setLayout() {
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
}

// MARK: - Modal panGesture

extension MusicPlayerViewController {
    
    func setDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanModalView))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc func didPanModalView(sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == .began {
            initialTouchPoint = touchPoint
        } else if sender.state == .changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == .ended || sender.state == .cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}
