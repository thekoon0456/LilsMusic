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
    
    private let chevronButton = UIButton().then {
        $0.setImage(UIImage(systemName: FMDesign.Icon.chevronDown.name), for: .normal)
        $0.tapAnimation()
    }
    
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
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
        $0.tapAnimation()
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
        $0.tapAnimation()
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addShadow()
        $0.tapAnimation()
    }
    
    private lazy var progressSlider = FMSlider(barHeight: 8).then {
        $0.isContinuous = true
        $0.minimumValue = 0
//        $0.setThumbImage(UIImage().applyingSymbolConfiguration(UIImage.SymbolConfiguration(font: 0.8)), for: .normal)
//        $0.setThumbImage(UIImage(), for: .highlighted)
        $0.layer.cornerRadius = 4
        $0.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped))
        $0.addGestureRecognizer(tapGesture)
        $0.progressAnimation()
//        $0.addShadow()
    }
    
    //상태에 따라 아이콘 바뀜
    private lazy var repeatButton = UIButton().then {
        $0.setImage(UIImage(systemName: "repeat"), for: .normal)
        $0.tintColor = FMDesign.Color.tintColor.color
        $0.addShadow()
        $0.tapAnimation()
    }
    
    //알파값 바뀜
    private lazy var shuffleButton = UIButton().then {
        $0.setImage(UIImage(systemName: "shuffle"), for: .normal)
        $0.tintColor = FMDesign.Color.tintColor.color
        $0.addShadow()
        $0.tapAnimation()
    }
    
    //상태에 따라 아이콘 바뀜
    private lazy var heartButton = UIButton().then {
        $0.setImage(UIImage(systemName: FMDesign.Icon.heart.name), for: .normal)
        $0.setImage(UIImage(systemName: FMDesign.Icon.heart.fill), for: .selected)
        $0.tintColor = FMDesign.Color.tintColor.color
        $0.addShadow()
        $0.tapAnimation()
    }
    
    //알파값 바뀜
    private lazy var playlistButton = FMPlaylistButton(menus: ["새 플레이리스트 만들기"]).then {
        $0.setImage(UIImage(systemName: FMDesign.Icon.library.name), for: .normal)
        $0.tintColor = FMDesign.Color.tintColor.color
        $0.addShadow()
        $0.tapAnimation()
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
            .asObservable()
        
        let repeatButtonTapped = repeatButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .asObservable()
        
        let shuffleButtonTapped = shuffleButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .asObservable()
        
        let heartButtonTapped = heartButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> Bool in
                guard let self else { return false }
                return heartButton.isSelected
            }
        
        let playlistButtonTapped = playlistButton.menuSelectionSubject
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { $0 }
        
        let input = MusicPlayerViewModel.Input(chevronButtonTapped: chevronButton.rx.tap,
                                               viewWillAppear: self.rx.viewWillAppear.map { _ in },
                                               playButtonTapped: playButtonTapped,
                                               previousButtonTapped: previousButton.rx.tap,
                                               nextButtonTapped: nextButton.rx.tap,
                                               repeatButtonTapped: repeatButtonTapped,
                                               shuffleButtonTapped: shuffleButtonTapped,
                                               heartButtonTapped: heartButtonTapped,
                                               playlistButtonTapped: playlistButtonTapped,
                                               viewWillDisappear: self.rx.viewWillDisappear.map { _ in })
        let output = viewModel.transform(input)
        
        output.updateEntry.drive(with: self) { owner, track in
            guard let track else { return }
            owner.updateUI(track)
        }.disposed(by: disposeBag)
        
        output.playState.drive(with: self) { owner, state in
            if state == .playing {
                owner.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
            } else {
                owner.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }.disposed(by: disposeBag)
        
        //버튼 UI 업데이트
        output.repeatMode.drive(with: self) { owner, mode in
            owner.setRepeatButton(mode)
        }.disposed(by: disposeBag)
        
        output.shuffleMode.drive(with: self) { owner, mode in
            owner.setShuffleButton(mode)
        }.disposed(by: disposeBag)
        
        output.isHeart.drive(with: self) { owner, bool in
            owner.heartButton.isSelected = bool
        }.disposed(by: disposeBag)
    }
    
    @objc func updateProgressBar() {
        let progress = viewModel.musicPlayer.getPlayBackTime() / Double(progressSlider.maximumValue)
        //첫 애니메이션 시작지점 설정
        guard progress > 0.05 else { return }
        let value = Float(viewModel.musicPlayer.getPlayBackTime())
        progressSlider.setValue(value, animated: true)
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
        //백그라운드 설정
        setGradient(startColor: track.artwork?.backgroundColor,
                    endColor: track.artwork?.backgroundColor)
        //progressSlider설정, 초기화
        progressSlider.maximumValue = Float(track.duration ?? 0)
        progressSlider.setValue(0, animated: true)
        let setting = UserDefaultsManager.shared
        setRepeatButton(setting.userSetting.repeatMode)
        setShuffleButton(setting.userSetting.shuffleMode)
    }
    
    func setRepeatButton(_ mode: RepeatMode) {
        switch mode {
        case .all, .one:
            repeatButton.setImage(UIImage(systemName: mode.iconName), for: .normal)
            repeatButton.alpha = 1
        case .off:
            repeatButton.setImage(UIImage(systemName: mode.iconName), for: .normal)
            repeatButton.alpha = 0.3
        }
    }
    
    func setShuffleButton(_ mode: ShuffleMode) {
        switch mode {
        case .on:
            shuffleButton.alpha = 1
        case .off:
            shuffleButton.alpha = 0.3
        }
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        super.configureHierarchy()
        view.addSubviews(chevronButton, artworkImage, songLabel, artistLabel, playButton,
                         previousButton, nextButton, progressSlider,
                         shuffleButton, repeatButton, heartButton, playlistButton)
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
        chevronButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.size.equalTo(44)
            make.centerX.equalToSuperview()
        }
        
        artworkImage.snp.makeConstraints { make in
            make.size.equalTo(300)
            make.centerX.equalToSuperview()
            make.top.equalTo(chevronButton.snp.bottom).offset(20)
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
        
        heartButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.top.equalTo(previousButton.snp.bottom).offset(20)
            make.leading.equalTo(progressSlider.snp.leading)
        }
        
        playlistButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalTo(heartButton.snp.centerY)
            make.trailing.equalTo(progressSlider.snp.trailing)
        }
        
        progressSlider.snp.makeConstraints { make in
            make.top.equalTo(heartButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(16)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.leading.equalTo(progressSlider.snp.leading)
            make.top.equalTo(progressSlider.snp.bottom).offset(16)
        }
        
        repeatButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.trailing.equalTo(progressSlider.snp.trailing)
            make.top.equalTo(progressSlider.snp.bottom).offset(16)
        }
    }
}

// MARK: - Modal panGesture

extension MusicPlayerViewController {
    
    func setDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dismissGesture))
        view.addGestureRecognizer(panGesture)
    }
    
    // 팬 제스처를 처리하는 메소드
    @objc func dismissGesture(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
        case .changed:
            if translation.y > 0 {
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
            break
        case .ended:
            if translation.y > 100 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.height)
                }) { [weak self] _ in
                    guard let self else { return }
                    dismiss(animated: true)
                }
            } else {
                UIView.animate(withDuration: 0.3) { [weak self] in
                    guard let self else { return }
                    view.transform = .identity
                }
            }
        default:
            break
        }
    }
}
