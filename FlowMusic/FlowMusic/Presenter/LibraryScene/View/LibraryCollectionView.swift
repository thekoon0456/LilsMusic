//
//  LibraryCollectionView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

//final class LibraryCollectionView: BaseCollectionView {
    
    // MARK: - Properties
    
//    private let viewModel: MusicRecommendViewModel
//    private let player = MusicPlayerManager.shared
//    private let request = MusicRequest.shared
    
//    private let titleView = UILabel().then {
//        $0.text = "Your Albums"
//        $0.font = .boldSystemFont(ofSize: 20)
//    }
//    
//    private lazy var collectionView = UICollectionView(frame: .zero,
//                                                       collectionViewLayout: createLayout())
//    private var dataSource: UICollectionViewDiffableDataSource<Int, Album>?
//    private var album: MusicItemCollection<Album>?
    
    // MARK: - Lifecycles
//    
//    init(viewModel: MusicRecommendViewModel) {
//        self.viewModel = viewModel
//        super.init()
//    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
        
//        collectionView.delegate = self
//        configureDataSource()
        
//        Task {
//            do {
//                album = try await request.requestCatalogAlbumCharts()
//                updateSnapshot()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//    }
    
//    private func configureDataSource() {
//        //1. 타입어노테이션 선언 or 타입 추론이 될 수 있도록
//        let cellRegistration = UICollectionView.CellRegistration<MusicChartsCell, Album> { cell, indexPath, itemIdentifier in
////            cell.configureCell(itemIdentifier)
//        }
//        
//        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
//            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
//            return cell
//        }
//    }
    
//    private func updateSnapshot() {
//        var snapshot = NSDiffableDataSourceSnapshot<Int, Album>()
//        snapshot.appendSections([1])
//        guard let albums: [Album] = (album?.map { $0 }) else { return }
//        snapshot.appendItems(albums, toSection: 1)
//        dataSource?.apply(snapshot)
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
    
//    // MARK: - Configure
//    
//    override func configureHierarchy() {
//        addSubview(collectionView)
//    }
//    
//    override func configureLayout() {
//        collectionView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//    }
//    
//    override func configureView() {
//        super.configureView()
//    }
//}
//
//extension MusicRecommendViewController: UICollectionViewDelegate {
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
////        guard var album = album?[indexPath.item] else { return }
//////        viewModel.input.push.onNext(album)
////        Task {
////            try await album = album.with(.tracks)
////            viewModel.coordinator?.push(album: album)
////            
////
////        }
//    }
//}
