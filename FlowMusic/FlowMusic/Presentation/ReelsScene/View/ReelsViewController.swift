//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

import SnapKit

final class ReelsViewController: BaseViewController {
    
    enum Section: CaseIterable {
        case main
    }
    
    // MARK: - Properties
    
    private let viewModel: ReelsViewModel
    private let musicRequest = MusicRequest.shared
    private var musicVideos: MusicItemCollection<MusicVideo>?
    private let titleView = UILabel().then {
        $0.text = "MV Reels"
        $0.font = .boldSystemFont(ofSize: 20)
    }

    private lazy var collectionView = {
        let cv = UICollectionView(frame: .zero,
                                  collectionViewLayout: createLayout())
        cv.delegate = self
        cv.isPagingEnabled = true
        return cv
    }()
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, MusicVideo>?
    
    // MARK: - Lifecycles
    
    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        
        Task {
            musicVideos = try await musicRequest.requestCatalogMVCharts().first
            print(musicVideos)
            updateSnapshot()
        }
        
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ReelsCell, MusicVideo> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        }
    }
    
    private func updateSnapshot() {
        guard let mv: [MusicVideo] = (musicVideos?.map { $0 }) else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, MusicVideo>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(mv, toSection: .main)
        dataSource?.apply(snapshot)
    }
    
    // MARK: - Layout
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    override func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
    }
}

extension ReelsViewController: UICollectionViewDelegate {
    

}
























