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
    
    private let player = MusicPlayerManager.shared
    private let request = MusicRequest.shared
    
    private var dataSource: DataSource?
    
    var songs: MusicItemCollection<Song>?
    var playlists: MusicItemCollection<Playlist>?
    var albums: MusicItemCollection<Album>?
    
    private lazy var collectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createSectionLayout())
        cv.register(TrendingHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrendingHeaderView.identifier)
        return cv
    }()
    
    private let titleView = UILabel().then {
        $0.text = "Trending"
        $0.font = .boldSystemFont(ofSize: 20)
    }
    
    private let musicRepository = MusicRepository()
    
    // MARK: - Lifecycles
    
    init(viewModel: MusicRecommendViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        configureSnapshot()
        
//        // MARK: - input
//        Task {
//            async let songsResult = request.requestCatalogSongCharts()
//            async let playlistResult = request.requestCatalogPlaylistCharts()
//            async let albumResult = request.requestCatalogAlbumCharts()
//            let (songs, playlists, albums) = try await (songsResult, playlistResult, albumResult)
//            
//            DispatchQueue.main.async {
//                self.songs = songs
//                self.playlists = playlists
//                self.albums = albums
//                self.updateSnapshotSection()
//            }
//        }
    }
    
    // MARK: - Helpers
    
    override func bind() {
        super.bind()
        
        let input = MusicRecommendViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in } )
        let output = viewModel.transform(input)
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
                    let item = owner.dataSource?.itemIdentifier(for: indexPath)
//                    self.viewModel.coordinator?.push(item: song)
                case .playlist:
                    let item = owner.dataSource?.itemIdentifier(for: indexPath)
//                    self.viewModel.coordinator?.push(item: playlist)
                case .album:
                    let item = owner.dataSource?.itemIdentifier(for: indexPath)
//                    self.viewModel.coordinator?.push(item: album)
                }
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        navigationItem.backButtonDisplayMode = .minimal
    }
}
//// MARK: - CollectionViewDelegate
//
//extension MusicRecommendViewController: UICollectionViewDelegate {
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let section = Section(rawValue: indexPath.section) else { return }
//        switch section {
//        case .trending:
//            guard let song = songs?[indexPath.row] else { return }
//            // MARK: - input
////            collectionView.rx.itemSelected
//            viewModel.coordinator?.push(item: song)
//        case .playlist:
//            guard let playlist = playlists?[indexPath.row] else { return }
//            // MARK: - input
//            viewModel.coordinator?.push(item: playlist)
//        case .album:
//            guard let album = albums?[indexPath.row] else { return }
//            // MARK: - input
//            viewModel.coordinator?.push(item: album)
//        }
//    }
//}

// MARK: - CollectionView Data

extension MusicRecommendViewController {
    
    private func configureDataSource() {
        print(#function)
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
        print(#function)
        var snapshot = dataSource?.snapshot() ?? Snapshot()
        
        let items = items.map { item -> Item in
            switch item {
            case let song as Song:
                return .song(song)
            case let playlist as Playlist:
                return .playlist(playlist)
            case let album as Album:
                return .album(album)
            default:
                fatalError("Unsupported item type")
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
