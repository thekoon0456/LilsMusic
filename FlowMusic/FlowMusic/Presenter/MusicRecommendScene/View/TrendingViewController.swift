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
    
    // MARK: - UI
    
    private lazy var collectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createSectionLayout())
        cv.register(TrendingHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrendingHeaderView.identifier)
        return cv
    }()
    
    private let titleView = UILabel().then {
        $0.text = "Trending"
        $0.font = .boldSystemFont(ofSize: 20)
    }
    
    private let miniPlayerView = MiniPlayerView()
    
    // MARK: - Lifecycles
    
    init(viewModel: MusicRecommendViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureSnapshot()
    }
    
    // MARK: - Helpers
    
    override func bind() {
        super.bind()
        
        let input = MusicRecommendViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in },
                                                  itemSelected: itemSelected.asObservable())
        let output = viewModel.transform(input)
        
        output.currentPlaySong.drive(with: self) { owner, track in
            guard let track else { return }
            owner.miniPlayerView.configureView(track)
        }.disposed(by: disposeBag)
        
        output.recommendSongs.drive(with: self) { owner, songs in
            owner.updateSnapshot(withItems: songs, toSection: .trending)
        }.disposed(by: disposeBag)
        
        output.recommendPlaylists.drive(with: self) { owner, playlist in
            owner.updateSnapshot(withItems: playlist, toSection: .playlist)
        }.disposed(by: disposeBag)
        
        output.recommendAlbums.drive(with: self) { owner, albums in
            owner.updateSnapshot(withItems: albums, toSection: .album)
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .withUnretained(self)
            .subscribe { owner, indexPath in
                guard let section = Section(rawValue: indexPath.section) else { return }
                switch section {
                case .trending:
                    guard let item = owner.dataSource?.itemIdentifier(for: indexPath) else { return }
                    if case let .song(song) = item {
                        owner.itemSelected.onNext(song)
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
                }
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Configure
    
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
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        navigationItem.backButtonDisplayMode = .minimal
    }
}

// MARK: - CollectionView DataSource

extension MusicRecommendViewController {
    
    private func configureDataSource() {
        let trendingCellRegistration = trendingCellRegistration()
        let playlistCellRegistration = playlistCellRegistration()
        let albumCellRegistration = albumCellRegistration()
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            guard let section = Section(rawValue: indexPath.section) else { return UICollectionViewCell() }
            switch section {
            case .trending:
                if case let .song(song) = itemIdentifier {
                    let cell = collectionView.dequeueConfiguredReusableCell(using: trendingCellRegistration, for: indexPath, item: song)
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
            case let song as Song:
                return .song(song)
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
        print(#function)
        let snapshot = Snapshot().then {
            $0.appendSections(Section.allCases)
        }
        dataSource?.apply(snapshot)
    }
}

// MARK: - CollectionView Layout

extension MusicRecommendViewController {
    
    enum Section: Int, CaseIterable {
        case trending
        case playlist
        case album
        
        var title: String {
            switch self {
            case .trending:
                "Trending Music"
            case .playlist:
                "Popular Playlist"
            case .album:
                "Best Albums"
            }
        }
    }
    
    enum Item: Hashable {
        case song(Song)
        case playlist(Playlist)
        case album(Album)
    }
    
    //CellRegistration
    
    private func trendingCellRegistration() -> UICollectionView.CellRegistration<MusicChartsCell, Song> {
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
    
    //layout
    
    private func createSectionLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            switch section {
            case .trending:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                       heightDimension: .fractionalHeight(0.3))
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
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                return section
            case .playlist:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.45),
                                                       heightDimension: .fractionalHeight(0.32))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                              leading: 0,
                                                              bottom: 0,
                                                              trailing: 12)
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [.init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                              heightDimension: .absolute(50)),
                                                            elementKind:  UICollectionView.elementKindSectionHeader,
                                                            alignment: .topLeading)]
                section.orthogonalScrollingBehavior = .groupPagingCentered
                return section
            case .album:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .fractionalHeight(1))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.6),
                                                       heightDimension: .fractionalHeight(0.5))
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
                section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
                return section
            }
        }
        
        return layout
    }
}
