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
    
    // MARK: - UI
    
    private lazy var searchController = UISearchController(searchResultsController: libraryCollectionViewController).then {
        $0.searchBar.placeholder = "Find Your Music"
        $0.searchBar.backgroundColor = .clear
        $0.searchBar.searchBarStyle = .minimal
        $0.searchBar.tintColor = FMDesign.Color.tintColor.color
        $0.searchBar.delegate = self
        $0.definesPresentationContext = true
    }
    
    private lazy var libraryCollectionViewController = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: UIScreen.main.bounds.width, height: 60)
        let cv = UICollectionViewController(collectionViewLayout: layout)
        cv.collectionView.delegate = nil
        cv.collectionView.dataSource = nil
        cv.collectionView.register(MusicListCell.self, forCellWithReuseIdentifier: MusicListCell.identifier)
        return cv
    }()
    
    private lazy var scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.addSubview(contentView)
        $0.refreshControl = refreshControl
    }
    
    private lazy var refreshControl = UIRefreshControl().then {
        $0.tintColor = .white
        $0.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private let contentView = UIView().then {
        $0.isUserInteractionEnabled = true
    }
    
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
        //        cv.dataSource = self
        //        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    //    private lazy var albumCollectionView = UICollectionView(frame: .zero,
    //                                                            collectionViewLayout: createLayout())
    //    private var dataSource: UICollectionViewDiffableDataSource<Section, Album>?
    //        private var album: MusicItemCollection<Album>?
    //
    //    //예전 컬렉션뷰 방식 사용
    //    var playlist: [(title: String, item: MusicItemCollection<Track>?)] = [] {
    //        didSet {
    //            playlistCollectionView.reloadData()
    //            //커버플로우 1번 인덱스부터 시작
    //            layout.setCurrentPage(1)
    //        }
    //    }
    
    // MARK: - Lifecycles
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewDidLoadTrigger.onNext(())
        
        //        configureDataSource()
        //                        Task {
        //                            self.playlist = try await viewModel.musicRepository.requestCatalogPlaylistCharts()
        //                        }
        
    }
    
    @objc func refreshData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            scrollView.refreshControl?.endRefreshing()
        }
    }
    
    override func bind() {
        super.bind()
        
        let searchText = searchController.searchBar.rx.text
            .orEmpty // nil을 방지하기 위해 빈 문자열로 변환
            .distinctUntilChanged() // 연속적인 중복 값 방지
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
        
        let miniPlayerPlayButtonTapped = miniPlayerView.playButton.rx.tap
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .asObservable()
        
        let modelSelected = libraryCollectionViewController.collectionView.rx.modelSelected(Track.self)
        let mixSelected = playlistCollectionView.rx.modelSelected(Playlist.self)
        
        let input = LibraryViewModel.Input(viewDidLoad: viewDidLoadTrigger,
                                           searchText: searchText,
                                           searchModelSelected: modelSelected,
                                           likedSongTapped: likedSongsButton.tap,
                                           recentlyPlayedSongTapped: recentlyPlayedButton.tap,
                                           itemSelected: itemSelected,
                                           mixSelected: mixSelected,
                                           miniPlayerTapped: miniPlayerView.tap,
                                           miniPlayerPlayButtonTapped: miniPlayerPlayButtonTapped,
                                           miniPlayerPreviousButtonTapped: miniPlayerView.previousButton.rx.tap,
                                           miniPlayerNextButtonTapped: miniPlayerView.nextButton.rx.tap)
        let output = viewModel.transform(input)
        
        output.searchResult
            .drive(libraryCollectionViewController.collectionView.rx.items(cellIdentifier: MusicListCell.identifier, cellType: MusicListCell.self)) { item, model, cell in
                cell.configureCell(model)
            }.disposed(by: disposeBag)
        
        //        output.mix.drive(with: self) { owner, playlist in
        //            print(playlist)
        //            owner.playlistSubject.onNext(playlist)
        //            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        //                owner.playlistCollectionView.reloadData()
        //            }
        //        }.disposed(by: disposeBag)
        
        
        output.mix
            .drive(playlistCollectionView.rx.items(cellIdentifier: LibraryCell.identifier, cellType: LibraryCell.self)) { [weak self] item, model, cell in
                guard let self else { return }
                cell.configureCell(model)
                //collectionView1번부터
                layout.setCurrentPage(1)
                layout.scrollDirection = .horizontal
            }.disposed(by: disposeBag)
        
        output.currentPlaySong.drive(with: self) { owner, track in
            owner.updateMiniPlayer(track: track)
        }.disposed(by: disposeBag)
        
        output.playState.drive(with: self) { owner, state in
            print(state)
            if state == .playing {
                owner.miniPlayerView.playButton.setImage(UIImage(systemName: "pause"), for: .normal)
            } else {
                owner.miniPlayerView.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }
        }.disposed(by: disposeBag)
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
        contentView.addSubviews(playlistCollectionView,
                                likedSongsButton,
                                recentlyPlayedButton)
    }
    
    override func configureLayout() {
        super.configureLayout()
        scrollView.snp.makeConstraints { make in
            make.size.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(scrollView)
            make.width.equalToSuperview()
//            make.height.equalToSuperview()
        }
        
        playlistCollectionView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top)
            make.width.equalTo(contentView.snp.width)
            make.height.equalTo(220)
        }
        
        likedSongsButton.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalTo(recentlyPlayedButton.snp.leading).offset(-20)
            make.height.equalTo(likedSongsButton.snp.width)
            make.width.equalTo(recentlyPlayedButton.snp.width)
            make.bottom.equalToSuperview()
        }
        
        recentlyPlayedButton.snp.makeConstraints { make in
            make.top.equalTo(playlistCollectionView.snp.bottom)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(recentlyPlayedButton.snp.width)
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        navigationItem.backButtonDisplayMode = .minimal
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

// MARK: - SearchBar

extension LibraryViewController: UISearchBarDelegate {
    
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

//// MARK: - CoverFlowCollectionView
//
//extension LibraryViewController: UICollectionViewDataSource, UICollectionViewDelegate {
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        print(#function)
//        guard let count = try? playlistSubject.value().count else { return 0 }
//        print(count)
//        return count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LibraryCell.identifier, for: indexPath) as? LibraryCell,
//              let playlists = try? playlistSubject.value()
//        else {
//            return UICollectionViewCell()
//        }
//        print(cell)
//        print(playlists[indexPath.item])
//        cell.configureCell(playlists[indexPath.item])
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let playlists = try? playlistSubject.value() else { return }
//        Task {
//            viewModel.coordinator?.pushToList(playlist: playlists[indexPath.item])
//        }
//    }
//}

// MARK: - AlbumCollectionView

//extension LibraryViewController {
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
