//
//  TrendingViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import MusicKit
import UIKit

import RxCocoa
import RxSwift
import SnapKit

final class MusicRecommendViewController: BaseViewController {
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    
    // MARK: - Properties
    
    private let viewModel: MusicRecommendViewModel
    private var dataSource: DataSource?
    private let itemSelected = PublishSubject<MusicItem>()
    private let viewDidLoadTrigger = PublishSubject<Void>()
    
    // MARK: - UI
    
    private lazy var searchController = UISearchController(searchResultsController: libraryCollectionViewController).then {
        $0.searchBar.placeholder = "Find Your Music"
        $0.searchBar.backgroundColor = .clear
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.tintColor = .tintColor
        $0.searchBar.delegate = self
        $0.definesPresentationContext = true
    }
    
    private lazy var libraryCollectionViewController = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: UIScreen.main.bounds.width, height: 60)
        let cv = UICollectionViewController(collectionViewLayout: layout)
        cv.view.backgroundColor = .bgColor
        cv.collectionView.delegate = nil
        cv.collectionView.dataSource = nil
        cv.collectionView.register(MusicListCell.self, forCellWithReuseIdentifier: MusicListCell.identifier)
        return cv
    }()
    
    private lazy var collectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createSectionLayout())
        cv.backgroundColor = .bgColor
        cv.register(TrendingHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrendingHeaderView.identifier)
        return cv
    }()
    
    let iconView = UIImageView().then {
        $0.image = UIImage(named: "lil")
        $0.contentMode = .scaleAspectFit
        $0.snp.makeConstraints { make in
            make.size.equalTo(44)
        }
    }
    
    private let titleView = UILabel().then {
        $0.text = "Trending"
        $0.font = .boldSystemFont(ofSize: 20)
    }
    
    private let miniPlayerView = MiniPlayerView().then {
        $0.isHidden = true
        $0.alpha = 0
    }

    // MARK: - Lifecycles
    
    init(viewModel: MusicRecommendViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureSnapshot()
        viewDidLoadTrigger.onNext(())
    }
    
    // MARK: - Helpers
    
    override func bind() {
        super.bind()
        
        let searchText = searchController.searchBar.rx.text
            .orEmpty
            .distinctUntilChanged() // 연속적인 중복 값 방지
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
        let modelSelected = libraryCollectionViewController.collectionView.rx.modelSelected(Track.self)
        
        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .asObservable()
        
        let input = MusicRecommendViewModel.Input(viewDidLoad: viewDidLoadTrigger,
                                                  searchText: searchText,
                                                  searchModelSelected: modelSelected,
                                                  itemSelected: itemSelected.asObservable(),
                                                  miniPlayerTapped: miniPlayerView.tap,
                                                  miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                                  miniPlayerPreviousButtonTapped: miniPlayerView.previousButton.rx.tap,
                                                  miniPlayerNextButtonTapped: miniPlayerView.nextButton.rx.tap)
        let output = viewModel.transform(input)
        
        output
            .searchResult
            .drive(libraryCollectionViewController.collectionView.rx.items(cellIdentifier: MusicListCell.identifier, cellType: MusicListCell.self)) { item, model, cell in
                cell.configureCell(model)
            }
            .disposed(by: disposeBag)
        
        output
            .currentPlaySong
            .drive(with: self) { owner, track in
            owner.updateMiniPlayer(track: track)
        }
        .disposed(by: disposeBag)
        
        output
            .recommendSongs
            .drive(with: self) { owner, songs in
            owner.updateSnapshot(withItems: songs, toSection: .top100)
        }
        .disposed(by: disposeBag)
        
        output
            .recommendPlaylists
            .drive(with: self) { owner, playlist in
            owner.updateSnapshot(withItems: playlist, toSection: .playlist)
        }
            .disposed(by: disposeBag)
        
        output
            .recommendAlbums
            .drive(with: self) { owner, albums in
            owner.updateSnapshot(withItems: albums, toSection: .album)
        }
            .disposed(by: disposeBag)
        
        output
            .cityTop25
            .drive(with: self) { owner, mostPlayed in
              owner.updateSnapshot(withItems: mostPlayed, toSection: .cityTop25)
          }
            .disposed(by: disposeBag)
        
        output
            .playState
            .drive(with: self) { owner, state in
            owner.setPlayButton(state: state)
        }
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .withUnretained(self)
            .subscribe { owner, indexPath in
                guard let section = Section(rawValue: indexPath.section) else { return }
                switch section {
                case .top100:
                    guard let item = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    if case let .playlist(playlist) = item {
                        owner.itemSelected.onNext(playlist)
                    }
                case .playlist:
                    guard let item = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    if case let .playlist(playlist) = item {
                        owner.itemSelected.onNext(playlist)
                    }
                case .album:
                    guard let item = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    if case let .album(album) = item {
                        owner.itemSelected.onNext(album)
                    }
                case .cityTop25:
                    guard let item = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    if case let .playlist(playlist) = item {
                        owner.itemSelected.onNext(playlist)
                    }
                }
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Configure
    
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
        super.configureHierarchy()
        view.addSubviews(collectionView, miniPlayerView)
    }
    
    override func configureLayout() {
        super.configureLayout()
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        miniPlayerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconView)
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

// MARK: - SearchBar

extension MusicRecommendViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let inputText = searchBar.text,
              inputText.count < 30 else { return false } //30자 제한
        
        let input = (inputText as NSString).replacingCharacters(in: range, with: text)
        let trimmedText = input.trimmingCharacters(in: .whitespaces)
        let hasWhiteSpace = input != trimmedText
        return !hasWhiteSpace
    }
}

// MARK: - CollectionView DataSource

extension MusicRecommendViewController {
    
    private func configureDataSource() {
        let top100CellRegistration = top100CellRegistration()
        let playlistCellRegistration = playlistCellRegistration()
        let albumCellRegistration = albumCellRegistration()
        let mixRegistration = mixRegistration()
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            guard let section = Section(rawValue: indexPath.section) else { return UICollectionViewCell() }
            switch section {
            case .top100:
                if case let .playlist(playlist) = itemIdentifier {
                    let cell = collectionView.dequeueConfiguredReusableCell(using: top100CellRegistration, for: indexPath, item: playlist)
                    return cell
                }
            case .playlist:
                if case let .playlist(playlist) = itemIdentifier {
                    let cell = collectionView.dequeueConfiguredReusableCell(using: playlistCellRegistration, for: indexPath, item: playlist)
                    return cell
                }
            case .album:
                if case let .album(album) = itemIdentifier {
                    let cell = collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: album)
                    return cell
                }
            case .cityTop25:
                if case let .playlist(playlist) = itemIdentifier {
                    let cell = collectionView.dequeueConfiguredReusableCell(using: mixRegistration, for: indexPath, item: playlist)
                    return cell
                }
            }
            return UICollectionViewCell()
        }
        
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrendingHeaderView.identifier, for: indexPath) as? TrendingHeaderView,
                  let section = Section(rawValue: indexPath.section)
            else {
                return UICollectionReusableView()
            }
            headerView.setTitle(section.title)
            return headerView
        }
    }
    
    private func updateSnapshot<T: Hashable>(withItems items: MusicItemCollection<T>, toSection section: Section) {
        var snapshot = dataSource?.snapshot() ?? Snapshot()
        
        let items = items.compactMap { item -> Item? in
            switch item {
            case let playlist as Playlist:
                return .playlist(playlist)
            case let album as Album:
                return .album(album)
            default:
                return nil
            }
        }
        snapshot.appendItems(items, toSection: section)
        dataSource?.apply(snapshot)
    }
    
    //섹션 세개만 먼저 세팅
    private func configureSnapshot() {
        let snapshot = Snapshot().then {
            $0.appendSections(Section.allCases)
        }
        dataSource?.apply(snapshot)
    }
}

// MARK: - CollectionView Layout

extension MusicRecommendViewController {
    
    enum Section: Int, CaseIterable {
        case top100
        case playlist
        case album
        case cityTop25
        
        var title: String {
            switch self {
            case .top100:
                "Top 100"
            case .playlist:
                "Popular Playlist"
            case .album:
                "Best Albums"
            case .cityTop25:
                "City Top 25"
            }
        }
    }
    
    enum Item: Hashable {
        case playlist(Playlist)
        case album(Album)
    }
    
    //CellRegistration
    
    private func top100CellRegistration() -> UICollectionView.CellRegistration<MusicChartsCell, Playlist> {
        UICollectionView.CellRegistration { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
    }
    
    private func playlistCellRegistration() -> UICollectionView.CellRegistration<PlaylistCell, Playlist> {
        UICollectionView.CellRegistration { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
    }
    
    private func albumCellRegistration() -> UICollectionView.CellRegistration<AlbumArtCell, Album> {
        UICollectionView.CellRegistration { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
    }
    
    private func mixRegistration() -> UICollectionView.CellRegistration<MixCell, Playlist> {
        UICollectionView.CellRegistration { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
    }
    
    //layout
    
    private func createSectionLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .top100:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                       heightDimension: .fractionalWidth(0.5))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 12,
                                                              bottom: 12,
                                                              trailing: 0)
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                              heightDimension: .absolute(50)),
                                                            elementKind:  UICollectionView.elementKindSectionHeader,
                                                            alignment: .topLeading)]
                section.orthogonalScrollingBehavior = .groupPagingCentered
                return section
            case .playlist, .cityTop25:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.45),
                                                       heightDimension: .fractionalWidth(0.57))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 12,
                                                              bottom: 12,
                                                              trailing: 0)
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                              heightDimension: .absolute(50)),
                                                            elementKind:  UICollectionView.elementKindSectionHeader,
                                                            alignment: .topLeading)]
                section.orthogonalScrollingBehavior = .groupPaging
                return section
            case .album:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6),
                                                       heightDimension: .fractionalWidth(0.7))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 12,
                                                              bottom: 0,
                                                              trailing: 0)
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                              heightDimension: .absolute(50)),
                                                            elementKind:  UICollectionView.elementKindSectionHeader,
                                                            alignment: .topLeading)]
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                return section
            }
        }
        
        return layout
    }
}
