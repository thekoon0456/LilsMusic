//
//  MusicListViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

import SnapKit
import Kingfisher

final class MusicListViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: MusicListViewModel
    
    private let player = MusicPlayerManager.shared
    private let request = MusicRequest.shared
    var tracks: MusicItemCollection<Track>?
    var item: MusicItem
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.delegate = self
        $0.backgroundColor = .clear
    }
    private var dataSource: UICollectionViewDiffableDataSource<Int, Track>?
    
    private let artworkImageView = UIImageView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }
    
    private let albumlabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16)
        $0.textAlignment = .center
    }
    private let artistlabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .lightGray
        $0.textAlignment = .center
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: MusicListViewModel, item: MusicItem) {
        self.viewModel = viewModel
        self.item = item
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let item = item as? Playlist {
            Task {
                tracks = try await request.playlistToTracks(item)
                loadDataAndUpdateUI()
            }
        }
        
        if let item = item as? Album {
            Task {
                tracks = try await request.albumToTracks(item)
                loadDataAndUpdateUI()
            }
        }
        
        
        player.setRepeatMode(mode: .all)
        readyFadeInAnimation()
        loadDataAndUpdateUI()
    }
    
    func loadDataAndUpdateUI() {
        configureDataSource()
        
        Task {
//            album = try await album ?? []

            guard let track = tracks?.first else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                updateUI(with: track)
                fadeInAnimation()
                updateSnapshot()
            }

        }
    }
    
    func updateUI(with track: Track) {
        artworkImageView.kf.setImage(with: track.artwork?.url(width: 300, height: 300))
        setGradient(startColor: track.artwork?.backgroundColor,
                    endColor: track.artwork?.backgroundColor)
        albumlabel.text = track.title
        artistlabel.text = track.artistName
    }
    
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        view.addSubviews(artworkImageView, albumlabel, artistlabel, collectionView)
    }
    
    override func configureLayout() {
        artworkImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
            make.size.equalTo(200)
        }
        
        albumlabel.snp.makeConstraints { make in
            make.top.equalTo(artworkImageView.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        artistlabel.snp.makeConstraints { make in
            make.top.equalTo(albumlabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(artistlabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    override func configureView() {
        super.configureView()
    }
}

// MARK: - Animation

extension MusicListViewController {
    
    func readyFadeInAnimation() {
        artworkImageView.alpha = 0
        albumlabel.alpha = 0
        artistlabel.alpha = 0
    }
    
    func fadeInAnimation() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            artworkImageView.alpha = 1
            albumlabel.alpha = 1
            artistlabel.alpha = 1
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
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Track>()
        snapshot.appendSections([1])
//        guard let track = (tracks.map { $0 }) else { return }
        guard let tracks else { return }
        snapshot.appendItems(Array(tracks), toSection: 1)
        dataSource?.apply(snapshot)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
}

extension MusicListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tracks else { return }
        Task {
            try await player.setTrackQueue(item: tracks, startIndex: indexPath.item)
            viewModel.coordinator?.present(track: tracks[indexPath.item])
        }
        
//        viewModel.input.listTapped.onNext(track)
    }
}
