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
    private let player = MusicPlayerManager.shared
    private let request = MusicRequest.shared
    private let layout = CollectionViewPagingLayout()
    
    private let titleView = UILabel().then {
        $0.text = "Library"
        $0.font = .boldSystemFont(ofSize: 20)
    }
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.register(LibraryCell.self, forCellWithReuseIdentifier: LibraryCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    var playlist: MusicItemCollection<Playlist>? {
        didSet {
            collectionView.reloadData()
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
        Task {
            self.playlist = try await request.requestCatalogPlaylistCharts()
//            print(playlist)
        }
    }
    override func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(250)
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
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
        guard var playlist else { return }
        Task {
//            playlist = try await MusicRequest.playlistToTracks(playlist)
            viewModel.coordinator?.pushToList(playlist: playlist[indexPath.item])
        }

    }
}
