//
//  MusicListViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

import RxCocoa
import RxSwift
import SnapKit
import Kingfisher

final class MusicListViewController: BaseViewController {
    
    enum Section: Int, CaseIterable {
        case main
    }
    
    // MARK: - Properties
    
    private let viewModel: MusicListViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Section, Track>?
    private let itemSelected = PublishSubject<(index: Int, track: Track)>()
    
    // MARK: - UI
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .clear
    }
    
    private let artworkImageView = UIImageView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
    private let artistLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    private lazy var playButton = UIButton().then {
        $0.setImage(UIImage(systemName: "play.fill"), for: .normal)
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
    
    private let miniPlayerView = MiniPlayerView().then {
        $0.isHidden = true
        $0.alpha = 0
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: MusicListViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readyFadeInAnimation()
        configureDataSource()
    }
    
    override func bind() {
        super.bind()
        
        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> Bool in
                guard let self else { return true }
                return !miniPlayerView.playButton.isSelected
            }
        
        let input = MusicListViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in },
                                             itemSelected: itemSelected.asObservable(),
                                             miniPlayerTapped: miniPlayerView.tap,
                                             miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                             miniPlayerPreviousButtonTapped: miniPlayerView.previousButton.rx.tap,
                                             miniPlayerNextButtonTapped: miniPlayerView.nextButton.rx.tap)
        let output = viewModel.transform(input)
        
        output.item.drive(with: self) { owner, item in
            guard let item else { return }
            owner.updateUI(item)
        }.disposed(by: disposeBag)
        
        output.tracks.drive(with: self) { owner, tracks in
            owner.updateSnapshot(tracks: tracks)
            owner.fadeInAnimation()
        }.disposed(by: disposeBag)
        
        output.currentPlaySong.drive(with: self) { owner, track in
            guard let track else {
                owner.miniPlayerView.isHidden = true
                owner.miniPlayerView.alpha = 0
                return
            }
            owner.miniPlayerView.isHidden = false
            owner.miniPlayerView.configureView(track)
            UIView.animate(withDuration: 0.5) {
                owner.miniPlayerView.alpha = 1
            }
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .withUnretained(self)
            .subscribe { owner, indexPath in
                guard let track = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                owner.itemSelected.onNext((index: indexPath.item, track: track))
            }.disposed(by: disposeBag)
        
        output.miniPlayerPlayState.drive(with: self) { owner, bool in
            owner.miniPlayerView.playButton.isSelected = bool
        }.disposed(by: disposeBag)
        
    }
    
    func updateUI(_ item: MusicItem) {
        switch item {
        case let playlist as Playlist:
            artworkImageView.kf.setImage(with: playlist.artwork?.url(width: 300, height: 300))
            setGradient(startColor: playlist.artwork?.backgroundColor,
                        endColor: playlist.artwork?.backgroundColor)
            titleLabel.text = playlist.name
            artistLabel.text = playlist.shortDescription
        case let album as Album:
            artworkImageView.kf.setImage(with: album.artwork?.url(width: 300, height: 300))
            setGradient(startColor: album.artwork?.backgroundColor,
                        endColor: album.artwork?.backgroundColor)
            titleLabel.text = album.title
            artistLabel.text = album.artistName
        default:
            return
        }
    }
    
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        view.addSubviews(artworkImageView, titleLabel, artistLabel, playButton, shuffleButton, collectionView, miniPlayerView)
    }
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.backButtonDisplayMode = .minimal
    }
}

// MARK: - Animation

extension MusicListViewController {
    
    func readyFadeInAnimation() {
        artworkImageView.alpha = 0
        //        artworkImageView.snp.makeConstraints { make in
        //            make.size.equalTo(300)
        //            make.centerX.equalToSuperview()
        //        }
        titleLabel.alpha = 0
        artistLabel.alpha = 0
    }
    
    func fadeInAnimation() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            artworkImageView.alpha = 1
            titleLabel.alpha = 1
            artistLabel.alpha = 1
        }
    }
}

// MARK: - CollectionView

extension MusicListViewController {
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<MusicListCell, Track> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        }
    }
    
    private func updateSnapshot(tracks: MusicItemCollection<Track>) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Track>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(Array(tracks), toSection: .main)
        dataSource?.apply(snapshot)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
}

// MARK: - Layout

extension MusicListViewController {
    
    private func setLayout() {
        artworkImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
            make.size.equalTo(200)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        artistLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(artistLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        miniPlayerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }
}
