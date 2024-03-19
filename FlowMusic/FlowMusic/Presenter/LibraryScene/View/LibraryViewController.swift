//
//  LibraryViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

import CollectionViewPagingLayout

final class LibraryViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: LibraryViewModel
    private let musicPlayer = FMMusicPlayer()
    private let request = MusicRepository()
    private let layout = CollectionViewPagingLayout()
    
    // MARK: - UI
    
    private lazy var scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.addSubview(contentView)
        $0.refreshControl = refreshControl
    }
    
    let refreshControl = UIRefreshControl().then {
        $0.tintColor = .white
    }
    
    private let contentView = UIView()
    
    private let likedSongsButton = LibraryButtonView(imageName: "heart.fill",
                                                     title: "Liked Songs",
                                                     subTitle: "",
                                                     bgColor: .systemPink)
    
    private let recentlyPlayedButton = LibraryButtonView(imageName: "play.circle",
                                                         title: "Recently\nPlayed Songs",
                                                         subTitle: "",
                                                         bgColor: FMDesign.Color.tintColor.color)
    
    private let miniPlayerView = MiniPlayerView().then {
        $0.isHidden = true
        $0.alpha = 0
    }
    
    private let titleView = UILabel().then {
        $0.text = "Library"
        $0.font = .boldSystemFont(ofSize: 20)
    }
    
    private lazy var playlistCollectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.register(LibraryCell.self, forCellWithReuseIdentifier: LibraryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private lazy var albumCollectionView = UICollectionView(frame: .zero,
                                                            collectionViewLayout: createLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Section, Album>?
    //        private var album: MusicItemCollection<Album>?
    
    var playlist: MusicItemCollection<Playlist>? {
        didSet {
            playlistCollectionView.reloadData()
            //커버플로우 1번 인덱스부터 시작
            layout.setCurrentPage(1)
        }
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        
        Task {
            self.playlist = try await request.requestCatalogPlaylistCharts()
        }
    }
    override func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(playlistCollectionView,
                                likedSongsButton,
                                recentlyPlayedButton,
                                albumCollectionView)
    }
    
    override func configureLayout() {
        
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(scrollView)
            make.width.equalToSuperview()
        }
        
        playlistCollectionView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(200)
        }
        
        likedSongsButton.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(recentlyPlayedButton.snp.leading).offset(-10)
            make.height.equalTo(likedSongsButton.snp.width)
            make.width.equalTo(recentlyPlayedButton.snp.width)
        }
        
        recentlyPlayedButton.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom).offset(20)
            make.leading.equalTo(likedSongsButton.snp.trailing).offset(-10)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(recentlyPlayedButton.snp.width)
        }
        
        albumCollectionView.snp.makeConstraints { make in
            make.top.equalTo(likedSongsButton.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        navigationItem.backButtonDisplayMode = .minimal
    }
}

extension LibraryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let playlist else { return 0 }
        return playlist.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryCell.identifier, for: indexPath) as? LibraryCell,
              let playlist = playlist?[indexPath.item]
        else { return UICollectionViewCell() }
        cell.configureCell(playlist)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.item)
        guard let playlist else { return }
        Task {
            viewModel.coordinator?.pushToList(playlist: playlist[indexPath.item])
        }
    }
}

// MARK: - AlbumCollectionView

extension LibraryViewController {
    
    enum Section: Int, CaseIterable {
        case album
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<AlbumArtCell, Album> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: albumCollectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        }
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalWidth(0.5))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
