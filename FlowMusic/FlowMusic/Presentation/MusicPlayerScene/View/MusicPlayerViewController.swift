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
    }
    
    private let songLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18)
        $0.textColor = .white
        $0.textAlignment = .center
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
    }
    
    private lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.fill"), for: .normal)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
    }
    
    private lazy var progressBar = UIProgressView(progressViewStyle: .default).then {
        $0.tintColor = .systemGray6
        $0.backgroundColor = .clear
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(pregressBarSlide))
        $0.addGestureRecognizer(gesture)
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
        
        player.getCurrentPlayer().queue.objectWillChange.sink { _ in
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
        }
    }
    
    // MARK: - Selectors
    
    @objc func pregressBarSlide(sender: UISwipeGestureRecognizer) {
        let point = sender.location(in: progressBar)
        let progressBarWidth = 300
        let percentage = Double(point.x / CGFloat(progressBarWidth))
        let duration = player.getPlayBackTime()
        let seekTime = percentage * duration
        
        // TODO: - 프로그레스바 이동 추가
    }
    
    @objc func updateProgressBar() {
        let progress = Float(player.getPlayBackTime() / (track.duration ?? 0))
        progressBar.setProgress(progress, animated: true)
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
                try await updateCurrentEntryUI()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc private func nextButtonTapped(sender: UIButton) {
        Task {
            try await player.skipToNext()
            try await updateCurrentEntryUI()
        }
    }
    
    // MARK: - Helpers
    
    func updateCurrentEntryUI() async throws {
        Task {
            let entry = try await player.getCurrentEntry()
            guard let song = try await musicRequest.requestSearchSongIDCatalog(id: entry?.item?.id) else { return }
            print(song)
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                //여기서 하면 현재 엔트리가 나와
                artworkImage.kf.setImage(with: song.artwork?.url(width: 300, height: 300))
                artistLabel.text =  song.artistName
                songLabel.text = song.title
            }
        }
    }
    
    
    private func setProgressBarTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateProgressBar),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    override func configureHierarchy() {
        view.addSubviews(artworkImage, songLabel, artistLabel, playButton, previousButton, nextButton, progressBar)
    }
    
    override func configureLayout() {
        artworkImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(300)
            make.top.equalToSuperview().offset(100)
        }
        
        songLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImage.snp.bottom).offset(20)
            make.width.equalToSuperview()
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(songLabel.snp.bottom).offset(4)
            make.width.equalToSuperview()
        }
        
        previousButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton.snp.centerY)
            make.trailing.equalTo(playButton.snp.leading).offset(-20)
        }
        
        playButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
            make.size.equalTo(60)
        }
        
        nextButton.snp.makeConstraints { make in
            make.centerY.equalTo(playButton.snp.centerY)
            make.leading.equalTo(playButton.snp.trailing).offset(20)
        }
        
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(8)
            make.top.equalTo(playButton.snp.bottom).offset(20)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        sheetPresentationController?.prefersGrabberVisible = true
    }
}

// MARK: - MediaPicker

//    @objc private func presentLibrary(sender: UIButton) {
//        let controller = MPMediaPickerController(mediaTypes: .music)
//        controller.allowsPickingMultipleItems = true
//        controller.popoverPresentationController?.sourceView = sender
//        controller.delegate = self
//        present(controller, animated: true)
//    }

//
// MARK: - MediaPicker
//
//extension PlayViewController: MPMediaPickerControllerDelegate {
//    func mediaPicker(_ mediaPicker: MPMediaPickerController,
//                     didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
//        // Get the system music player.
//        player.player.setQueue(with: mediaItemCollection)
//        let item = mediaItemCollection.items.first
//
//        DispatchQueue.main.async { [weak self] in
//            guard let self else { return }
//            artistLabel.text = item?.albumTitle
//            songLabel.text = item?.title
//            artworkImage.image = item?.artwork?.image(at: .init(width: 300, height: 300))
//        }
//
//        mediaPicker.dismiss(animated: true)
//        // Begin playback.
//        player.player.prepareToPlay()
//        player.player.play()
//    }
//
//
//    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
//        mediaPicker.dismiss(animated: true)
//    }
//}
