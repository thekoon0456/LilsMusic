//
//  MusicViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//
import MusicKit
import UIKit

import Kingfisher
import SnapKit
import RxCocoa
import RxSwift

final class MusicPlayerViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: MusicPlayerViewModel
    private var timer: Timer?
    
    // MARK: - UI
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).then {
        $0.alpha = 0.3
    }
    
    private let chevronButton = UIButton().then {
        let image = UIImage(systemName: "chevron.down")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }

    private lazy var heartButton = UIButton().then {
        let image = UIImage(systemName: FMDesign.Icon.heart.name)?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
        let fillImage = UIImage(systemName: FMDesign.Icon.heart.fill)?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
        $0.setImage(image, for: .normal)
        $0.setImage(fillImage, for: .selected)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    //알파값 바뀜
    private lazy var playlistButton = FMPlaylistButton(menus: ["새 플레이리스트 만들기"]).then {
        let image = UIImage(systemName: FMDesign.Icon.library.name)?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    private let songLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .bgColor
        $0.textAlignment = .center
    }
    
    private let artistLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18)
        $0.textColor = .bgColor
        $0.textAlignment = .center
    }
    
    private var artworkImage = UIImageView().then {
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray
    }
    
    private lazy var playButton = UIButton().then {
        let image = UIImage(systemName: "pause.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 44)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    private lazy var nextButton = UIButton().then {
        let image = UIImage(systemName: "forward.end.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    private lazy var previousButton = UIButton().then {
        let image = UIImage(systemName: "backward.end.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    private lazy var progressSlider = FMSlider(barHeight: 8).then {
        $0.setThumbImage(UIImage(), for: .normal)
        $0.tintColor = .bgColor
        $0.layer.cornerRadius = 4
        $0.isContinuous = true
        $0.minimumValue = 0
        $0.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped))
        $0.addGestureRecognizer(tapGesture)
        $0.progressAnimation()
    }
    
    private let playTimeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 10)
        $0.text = "00:00"
        $0.textColor = .bgColor
        $0.textAlignment = .center
    }
    
    private let endTimeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 10)
        $0.text = "00:00"
        $0.textColor = .bgColor
        $0.textAlignment = .center
    }
    
    private lazy var repeatButton = UIButton().then {
        let image = UIImage(systemName: "repeat")
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.contentHorizontalAlignment = .trailing
        $0.contentVerticalAlignment = .top
        $0.tapAnimation()
    }
    
    private lazy var shuffleButton = UIButton().then {
        let image = UIImage(systemName: "shuffle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.contentHorizontalAlignment = .leading
        $0.contentVerticalAlignment = .top
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
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .asObservable()
        
        let repeatButtonTapped = repeatButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .asObservable()
        
        let shuffleButtonTapped = shuffleButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
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
            owner.updatePlayButton(state: state)
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
    
    // MARK: - Selectors
    
    @objc func updateProgressBar() {
        let playbackTime = viewModel.musicPlayer.getPlayBackTime()
        playTimeLabel.text = formatDuration(playbackTime)
        let progress = playbackTime / Double(progressSlider.maximumValue)
        guard progress > 0.02 else { return }
        let value = Float(playbackTime)
        progressSlider.setValue(value, animated: false)
    }
    
    @objc func sliderValueChanged(_ sender: UISlider) {
        let newValue = sender.value
        viewModel.musicPlayer.setPlayBackTime(value: Double(newValue))
        tapImpact()
    }
    
    @objc func sliderTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: progressSlider)
        let sliderWidth = progressSlider.frame.size.width
        let tapValue = tapPoint.x / sliderWidth
        let value = progressSlider.maximumValue * Float(tapValue)
        progressSlider.setValue(value, animated: true)
        viewModel.musicPlayer.setPlayBackTime(value: Double(value))
        tapImpact()
    }
    
    // MARK: - UI
    
    func updateUI(_ track: Track) {
        artworkImage.kf.setImage(with: track.artwork?.url(width: 600, height: 600))
        artistLabel.text = track.artistName
        songLabel.text = track.title
        endTimeLabel.text = formatDuration(track.duration)
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
    
    private func updatePlayButton(state:  MusicPlayer.PlaybackStatus) {
        if state == .playing {
            let image = UIImage(systemName: "pause.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 60)))
            playButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "play.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 60)))
            playButton.setImage(image, for: .normal)
        }
    }
    
    func setRepeatButton(_ mode: RepeatMode) {
        switch mode {
        case .all:
            let image = UIImage(systemName: mode.iconName)?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))
            repeatButton.setImage(image, for: .normal)
            repeatButton.alpha = 1
        case .one:
            let image = UIImage(systemName: mode.iconName)?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))
            repeatButton.setImage(image, for: .normal)
            repeatButton.alpha = 1
        case .off:
            let image = UIImage(systemName: mode.iconName)?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))
            repeatButton.setImage(image, for: .normal)
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
    
    func formatDuration(_ duration: TimeInterval?) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter.string(from: duration ?? 0) ?? "00:00"
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        super.configureHierarchy()
        view.addSubviews(blurView, chevronButton, artworkImage, songLabel, artistLabel, playButton,
                         previousButton, nextButton, progressSlider,
                         shuffleButton, repeatButton, heartButton, playlistButton, playTimeLabel, endTimeLabel)
    }
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    override func configureView() {
        super.configureView()
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
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
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        chevronButton.snp.makeConstraints { make in
            make.top.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.size.equalTo(44)
        }
        
        heartButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalTo(chevronButton.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
        }
        
//        playlistButton.snp.makeConstraints { make in
//            make.size.equalTo(44)
//            make.centerY.equalTo(chevronButton.snp.centerY)
//            make.trailing.equalToSuperview().offset(-16)
//        }
        
        artworkImage.snp.makeConstraints { make in
            make.size.equalTo(300)
            make.centerX.equalToSuperview()
            make.top.equalTo(chevronButton.snp.bottom).offset(20)
        }
        
        songLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImage.snp.bottom).offset(40)
            make.width.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(songLabel.snp.bottom).offset(4)
            make.width.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
        
        progressSlider.snp.makeConstraints { make in
            make.top.equalTo(artistLabel.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(16)
        }
        
        playTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(progressSlider.snp.leading)
            make.bottom.equalTo(progressSlider.snp.top).offset(-4)
        }
        
        endTimeLabel.snp.makeConstraints { make in
            make.trailing.equalTo(progressSlider.snp.trailing)
            make.bottom.equalTo(progressSlider.snp.top).offset(-4)
        }
        
        shuffleButton.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.leading.equalTo(progressSlider.snp.leading)
            make.top.equalTo(progressSlider.snp.bottom).offset(4)
        }
        
        repeatButton.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.trailing.equalTo(progressSlider.snp.trailing)
            make.top.equalTo(progressSlider.snp.bottom).offset(4)
        }
        
        previousButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerY.equalTo(playButton.snp.centerY)
            make.trailing.equalTo(playButton.snp.leading).offset(-40)
        }
        
        playButton.snp.makeConstraints { make in
            make.top.equalTo(progressSlider.snp.bottom).offset(80)
            make.size.equalTo(60)
            make.centerX.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton.snp.centerY)
            make.size.equalTo(44)
            make.leading.equalTo(playButton.snp.trailing).offset(40)
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
