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
    
    // MARK: - Properties
    
    private let viewModel: MusicListViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Section, Track>?
    private var headerItem: MusicItem?
    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let itemSelected = PublishSubject<(index: Int, track: Track)>()
    private let playButtonTapped = PublishSubject<Void>()
    private let shuffleButtonTapped = PublishSubject<Void>()
    
    // MARK: - UI
    
    private lazy var collectionView = UICollectionView(frame: .zero,
                                                       collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .clear
        $0.contentInsetAdjustmentBehavior = .never
        $0.register(ArtworkHeaderReusableView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: ArtworkHeaderReusableView.identifier)
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
        
        configureDataSource()
        viewDidLoadTrigger.onNext(())
    }
    
    override func bind() {
        super.bind()
        
        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> Bool in
                guard let self else { return true }
                return !miniPlayerView.playButton.isSelected
            }
        
        let input = MusicListViewModel.Input(viewDidLoad: viewDidLoadTrigger.asObservable(),
                                             itemSelected: itemSelected.asObservable(),
                                             playButtonTapped: playButtonTapped.asObservable(),
                                             shuffleButtonTapped: shuffleButtonTapped.asObservable(),
                                             miniPlayerTapped: miniPlayerView.tap,
                                             miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                             miniPlayerPreviousButtonTapped: miniPlayerView.previousButton.rx.tap,
                                             miniPlayerNextButtonTapped: miniPlayerView.nextButton.rx.tap,
                                             viewWillDisappear: self.rx.viewWillDisappear.map { _ in })
        let output = viewModel.transform(input)
        
        output.item.drive(with: self) { owner, item in
            guard let item else { return }
            owner.headerItem = item
        }.disposed(by: disposeBag)
        
        output.tracks.drive(with: self) { owner, tracks in
            owner.updateSnapshot(tracks: tracks)
        }.disposed(by: disposeBag)
        
        output.currentPlaySong.drive(with: self) { owner, track in
            owner.updateMiniPlayer(track: track)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .withUnretained(self)
            .subscribe { owner, indexPath in
                guard let track = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                owner.itemSelected.onNext((index: indexPath.item, track: track))
            }.disposed(by: disposeBag)
        
        output.playState.drive(with: self) { owner, state in
            owner.setPlayButton(state: state)
        }.disposed(by: disposeBag)
        
    }
    
    // MARK: - UI
    
    private func setPlayButton(state: MusicPlayer.PlaybackStatus) {
        if state == .playing {
            miniPlayerView.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
            let image = UIImage(systemName: "pause.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
            miniPlayerView.playButton.setImage(image, for: .normal)
        } else {
            let selectedImage = UIImage(systemName: "play.circle.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
            miniPlayerView.playButton.setImage(selectedImage, for: .normal)
        }
    }
    
    private func updateMiniPlayer(track: Track?) {
        guard let track else {
            miniPlayerView.isHidden = true
            miniPlayerView.alpha = 0
            return
        }
        miniPlayerView.isHidden = false
        miniPlayerView.configureView(track)
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }
            miniPlayerView.alpha = 1
        }
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        view.addSubviews(collectionView, miniPlayerView)
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

// MARK: - CollectionView

extension MusicListViewController {
    
    enum Section: Int, CaseIterable {
        case main
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<MusicListCell, Track> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        }
        
        dataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self,
                  kind == UICollectionView.elementKindSectionHeader,
                  let item = headerItem,
                  let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                                   withReuseIdentifier: ArtworkHeaderReusableView.identifier,
                                                                                   for: indexPath) as? ArtworkHeaderReusableView
            else {
                return UICollectionReusableView()
            }
            
            headerView.updateUI(item)
            
            headerView.playButton.rx.tap
                .withUnretained(self)
                .subscribe{ owner, _ in
                    owner.playButtonTapped.onNext(())
                }.disposed(by: disposeBag)
            
            headerView.shuffleButton.rx.tap
                .withUnretained(self)
                .subscribe{ owner, _ in
                    owner.shuffleButtonTapped.onNext(())
                }.disposed(by: disposeBag)
            return headerView
        }
    }
    
    private func updateSnapshot(tracks: MusicItemCollection<Track>) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Track>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(Array(tracks), toSection: .main)
        dataSource?.apply(snapshot)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(60))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(450))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            section.boundarySupplementaryItems = [header]
            
            return section
        }
        return layout
    }
}

// MARK: - Layout

extension MusicListViewController {
    
    private func setLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        miniPlayerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }
}
