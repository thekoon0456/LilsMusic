//
//  LibraryViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

import CollectionViewPagingLayout
import RxCocoa
import RxGesture
import RxSwift

final class LibraryViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: LibraryViewModel
    private let layout = CollectionViewPagingLayout()
    private let playlistItemSelected = PublishSubject<MusicItem>()
    private let likeItemSelected = PublishSubject<(index: IndexPath, track: Track)>()
    private let viewDidLoadTrigger = PublishSubject<Void>()
    private let playlistSubject = BehaviorSubject< MusicItemCollection<Playlist>>(value: [])
    private var dataSource: UICollectionViewDiffableDataSource<Section, Track>?
    
    // MARK: - UI
    
    private lazy var scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.addSubview(contentView)
    }
    
    private let contentView = UIView().then {
        $0.isUserInteractionEnabled = true
    }
    
    let iconView = UIImageView().then {
        $0.image = UIImage(named: "lil")
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
    }
    
    private let forYouLabel = UILabel().then {
        $0.text = "For you"
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .tintColor
    }
    
    private let forYouEmptyLabel = UILabel().then {
        $0.text = "An Apple Music account is required to use this app"
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .tintColor
        $0.isHidden = true
    }
    
    private let likeLabel = UILabel().then {
        $0.text = "Liked Songs"
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .tintColor
    }
    
    private let likeEmptyLabel = UILabel().then {
        $0.text = "Press the heart for your favorite music"
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .tintColor
        $0.isHidden = true
    }
    
    private lazy var playlistCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .bgColor
        cv.isPagingEnabled = true
        cv.register(LibraryCell.self, forCellWithReuseIdentifier: LibraryCell.identifier)
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private lazy var musicListCollectionView = UICollectionView(frame: .zero,
                                                                collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .clear
        $0.contentInsetAdjustmentBehavior = .never
        $0.register(TrendingHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrendingHeaderView.identifier)
        $0.register(TrendingFooterView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: TrendingFooterView.identifier)
    }
    
    private let miniPlayerView = MiniPlayerView().then {
        $0.isHidden = true
        $0.alpha = 0
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        updateSnapshot()
        viewDidLoadTrigger.onNext(())
    }
    
    override func bind() {
        super.bind()
        
        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .asObservable()
        
        let previousButtonTapped = miniPlayerView.previousButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .asObservable()
        
        let nextButtonTapped = miniPlayerView.nextButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .asObservable()
        
        let mixSelected = playlistCollectionView.rx.modelSelected(Playlist.self)
        
        let input = LibraryViewModel.Input(viewDidLoad: viewDidLoadTrigger,
                                           viewWillAppear: self.rx.viewWillAppear.map { _ in },
                                           playlistItemSelected: playlistItemSelected,
                                           likeItemSelected: likeItemSelected.asObservable(),
                                           mixSelected: mixSelected,
                                           miniPlayerTapped: miniPlayerView.tap,
                                           miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                           miniPlayerPreviousButtonTapped: previousButtonTapped,
                                           miniPlayerNextButtonTapped: nextButtonTapped)
        let output = viewModel.transform(input)
        
        output.mix
            .drive(playlistCollectionView.rx.items(cellIdentifier: LibraryCell.identifier, cellType: LibraryCell.self)) { [weak self] item, model, cell in
                guard let self else { return }
                cell.configureCell(model)
                //collectionView1번부터
                layout.setCurrentPage(1)
            }
            .disposed(by: disposeBag)
        
        output
            .mix
            .drive(with: self) { owner, value in
                owner.updateForyouEmptyLabel(model: value)
            }.disposed(by: disposeBag)
        
        output
            .recentlyPlayTracks
            .drive(with: self) { owner, tracks in
                owner.updateRecentlyPlayedSongsSnapshot(tracks: tracks)
            }
            .disposed(by: disposeBag)
        
        output
            .likeTracks
            .drive(with: self) { owner, tracks in
                owner.updateEmptyLabel(tracks: tracks)
                owner.updateLikedSongsSnapshot(tracks: tracks)
            }
            .disposed(by: disposeBag)
        
        output
            .currentPlaySong
            .drive(with: self) { owner, track in
                owner.updateMiniPlayer(track: track)
            }
            .disposed(by: disposeBag)
        
        output
            .playState
            .drive(with: self) { owner, state in
                owner.setPlayButton(state: state)
            }
            .disposed(by: disposeBag)
        
        musicListCollectionView.rx.itemSelected
            .withUnretained(self)
            .subscribe { owner, indexPath in
                guard let section = Section(rawValue: indexPath.section) else { return }
                switch section {
                case .recentlyPlayed:
                    guard let track = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    owner.likeItemSelected.onNext((index: indexPath, track: track))
                case .likedSongs:
                    guard let track = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    owner.likeItemSelected.onNext((index: indexPath, track: track))
                }
            }
            .disposed(by: disposeBag)
    }
    
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
    
    private func updateForyouEmptyLabel(model: MusicItemCollection<Playlist>) {
        forYouEmptyLabel.isHidden = model.isEmpty ? false : true
    }
    
    private func updateEmptyLabel(tracks: MusicItemCollection<Track>) {
        likeEmptyLabel.isHidden = tracks.isEmpty ? false : true
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
    
    override func configureHierarchy() {
        view.addSubviews(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(forYouLabel, playlistCollectionView, forYouEmptyLabel,
                                musicListCollectionView, likeEmptyLabel, miniPlayerView)
    }
    
    
    override func configureLayout() {
        super.configureLayout()
        setLayout()
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconView)
        navigationItem.backButtonDisplayMode = .minimal
    }
}


// MARK: - LikeListCollectionView

extension LibraryViewController {
    
    enum Section: Int, CaseIterable {
        case recentlyPlayed
        case likedSongs
        
        var title: String {
            switch self {
            case .recentlyPlayed:
                "Recently Played Songs"
            case .likedSongs:
                "Liked Songs"
            }
        }
        
        var emptyDescription: String {
            switch self {
            case .recentlyPlayed:
                "Play your music"
            case .likedSongs:
                "Press the heart for your favorite music"
            }
        }
    }
    
    private func configureDataSource() {
        let recentlyPlayedCellRegistration = UICollectionView.CellRegistration<MusicListCell, Track> {  cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        let likedCellRegistration = UICollectionView.CellRegistration<MusicListCell, Track> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: musicListCollectionView) { collectionView, indexPath, itemIdentifier in
            
            guard let section = Section(rawValue: indexPath.section) else { return UICollectionViewCell() }
            switch section {
            case .recentlyPlayed:
                let cell = collectionView.dequeueConfiguredReusableCell(using: recentlyPlayedCellRegistration, for: indexPath, item: itemIdentifier)
                return cell
            case .likedSongs:
                let cell = collectionView.dequeueConfiguredReusableCell(using: likedCellRegistration, for: indexPath, item: itemIdentifier)
                return cell
            }
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard let section = Section(rawValue: indexPath.section) else { return UICollectionReusableView() }
            if kind == UICollectionView.elementKindSectionHeader {
                guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrendingHeaderView.identifier, for: indexPath) as? TrendingHeaderView else { return UICollectionReusableView() }
                headerView.setTitle(section.title)
                return headerView
            } else if kind == UICollectionView.elementKindSectionFooter {
                guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrendingFooterView.identifier, for: indexPath) as? TrendingFooterView else { return UICollectionReusableView() }
                footerView.setTitle(section.emptyDescription)
                return footerView
            }
            
            return UICollectionReusableView()
        }
    }
    
    private func updateSnapshot() {
        let snapshot = NSDiffableDataSourceSnapshot<Section, Track>().then {
            $0.appendSections(Section.allCases)
        }
        dataSource?.apply(snapshot)
    }
    
    private func updateRecentlyPlayedSongsSnapshot(tracks: MusicItemCollection<Track>) {
        let snapshot = NSDiffableDataSourceSectionSnapshot<Track>().then {
            $0.append(Array(tracks))
        }
        
        setHideFooter(itemCount: snapshot.items.count, section: 0)
        dataSource?.apply(snapshot, to: .recentlyPlayed)
    }
    
    private func updateLikedSongsSnapshot(tracks: MusicItemCollection<Track>) {
        let snapshot = NSDiffableDataSourceSectionSnapshot<Track>().then {
            $0.append(Array(tracks))
        }
        
        setHideFooter(itemCount: snapshot.items.count, section: 1)
        dataSource?.apply(snapshot, to: .likedSongs)
    }
    
    func setHideFooter(itemCount: Int, section: Int) {
        musicListCollectionView
            .supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: section))?
            .isHidden = itemCount == 0 ? false : true
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .recentlyPlayed:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(60))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),
                                                       heightDimension: .absolute(192))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 8,
                                                              trailing: 8)
                let section = NSCollectionLayoutSection(group: group)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                           heightDimension: .absolute(50)),
                                                                         elementKind:  UICollectionView.elementKindSectionHeader,
                                                                         alignment: .topLeading)
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                           heightDimension: .absolute(24)),
                                                                         elementKind:  UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottomLeading)
                section.boundarySupplementaryItems = [header, footer]
                section.orthogonalScrollingBehavior = .groupPaging
                return section
            case .likedSongs:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                               subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                           heightDimension: .absolute(50)),
                                                                         elementKind:  UICollectionView.elementKindSectionHeader,
                                                                         alignment: .topLeading)
                let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                           heightDimension: .absolute(24)),
                                                                         elementKind:  UICollectionView.elementKindSectionFooter,
                                                                         alignment: .bottomLeading)
                section.boundarySupplementaryItems = [header, footer]
                return section
            }
        }
        
        return layout
    }
}

extension LibraryViewController {
    
    private func setLayout() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(scrollView)
            make.width.equalToSuperview()
        }
        
        forYouLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        
        forYouEmptyLabel.snp.makeConstraints { make in
            make.top.equalTo(forYouLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        
        playlistCollectionView.snp.makeConstraints { make in
            make.top.equalTo(forYouLabel.snp.bottom).offset(8)
            make.width.equalTo(contentView.snp.width)
            make.height.equalTo(220)
        }
        
        musicListCollectionView.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom).offset(8)
            make.height.equalTo(view.bounds.height * 0.7)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        miniPlayerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }
}
