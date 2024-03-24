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
    private let itemSelected = PublishSubject<MusicItem>()
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
    
    private let forYouLabel = UILabel().then {
        $0.text = "For you"
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .tintColor
    }
    
    private let likeLabel = UILabel().then {
        $0.text = "Library"
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .tintColor
    }
    
    private lazy var likeListCollectionView = UICollectionView(frame: .zero,
                                                       collectionViewLayout: createLayout()).then {
        $0.backgroundColor = .clear
        $0.contentInsetAdjustmentBehavior = .never
    }
    
    private lazy var playlistCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .bgColor
        cv.isPagingEnabled = true
        cv.register(LibraryCell.self, forCellWithReuseIdentifier: LibraryCell.identifier)
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    
    private let likedSongsButton = LibraryButtonView(imageName: "heart.fill",
                                                     title: "Liked Songs",
                                                     subTitle: "",
                                                     bgColor: .tintColor)
    
    private let recentlyPlayedButton = LibraryButtonView(imageName: "play.circle",
                                                         title: "Recently\nPlayed Songs",
                                                         subTitle: "",
                                                         bgColor:  .tintColor)
    
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
        viewDidLoadTrigger.onNext(())
    }

    override func bind() {
        super.bind()

        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .asObservable()
        let mixSelected = playlistCollectionView.rx.modelSelected(Playlist.self)
        
        let input = LibraryViewModel.Input(viewDidLoad: viewDidLoadTrigger,
                                           likedSongTapped: likedSongsButton.tap,
                                           recentlyPlayedSongTapped: recentlyPlayedButton.tap,
                                           itemSelected: itemSelected,
                                           mixSelected: mixSelected,
                                           miniPlayerTapped: miniPlayerView.tap,
                                           miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                           miniPlayerPreviousButtonTapped: miniPlayerView.previousButton.rx.tap,
                                           miniPlayerNextButtonTapped: miniPlayerView.nextButton.rx.tap)
        
        let output = viewModel.transform(input)
        
        output.mix
            .drive(playlistCollectionView.rx.items(cellIdentifier: LibraryCell.identifier, cellType: LibraryCell.self)) { [weak self] item, model, cell in
                guard let self else { return }
                cell.configureCell(model)
                //collectionView1번부터
                layout.setCurrentPage(1)
            }.disposed(by: disposeBag)
        
        output.currentPlaySong.drive(with: self) { owner, track in
            owner.updateMiniPlayer(track: track)
        }.disposed(by: disposeBag)
        
        output.playState.drive(with: self) { owner, state in
            owner.setPlayButton(state: state)
        }.disposed(by: disposeBag)
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
        view.addSubviews(scrollView, miniPlayerView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(forYouLabel, playlistCollectionView,
                                likeLabel, likeListCollectionView)
    }
    
    override func configureLayout() {
        super.configureLayout()
        scrollView.snp.makeConstraints { make in
            make.size.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(scrollView)
            make.width.equalToSuperview()
        }
        
        forYouLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        
        playlistCollectionView.snp.makeConstraints { make in
            make.top.equalTo(forYouLabel.snp.bottom).offset(8)
            make.width.equalTo(contentView.snp.width)
            make.height.equalTo(220)
        }
        
        likeLabel.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(12)
        }
        
        likeListCollectionView.snp.makeConstraints { make in
            make.top.equalTo(likeLabel.snp.bottom).offset(8)
            make.height.equalTo(view.bounds.height)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        //        albumCollectionView.snp.makeConstraints { make in
        //            make.top.equalTo(playlistCollectionView.snp.bottom).offset(20)
        //            make.horizontalEdges.equalToSuperview()
        //            make.bottom.equalToSuperview()
        //        }
        
        miniPlayerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: UIImageView(image: UIImage(systemName: "leaf.fill")))
        navigationItem.backButtonDisplayMode = .minimal
    }
}


// MARK: - LikeListCollectionView

extension LibraryViewController {
    
    enum Section: Int, CaseIterable {
        case main
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<MusicListCell, Track> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: likeListCollectionView) { collectionView, indexPath, itemIdentifier in
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

// MARK: - AlbumCollectionView

//extension LibraryViewController {


//    private lazy var albumCollectionView = UICollectionView(frame: .zero,
//                                                            collectionViewLayout: createLayout())
//    private var dataSource: UICollectionViewDiffableDataSource<Section, Album>?
//        private var album: MusicItemCollection<Album>?

//
//    enum Section: Int, CaseIterable {
//        case album
//    }
//
//    private func configureDataSource() {
//        let cellRegistration = UICollectionView.CellRegistration<AlbumArtCell, Album> { cell, indexPath, itemIdentifier in
//            cell.configureCell(itemIdentifier)
//        }
//
//        dataSource = UICollectionViewDiffableDataSource(collectionView: albumCollectionView) { collectionView, indexPath, itemIdentifier in
//            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
//            return cell
//        }
//    }
//
//    private func createLayout() -> UICollectionViewCompositionalLayout {
//        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalWidth(0.5))
//        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
//        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.5))
//        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
//        group.interItemSpacing = .fixed(10)
//        let section = NSCollectionLayoutSection(group: group)
//        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
//        let layout = UICollectionViewCompositionalLayout(section: section)
//        return layout
//    }
//}
