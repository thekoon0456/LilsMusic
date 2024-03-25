//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import MusicKit
import UIKit

import RxCocoa
import RxSwift
import SnapKit

final class ReelsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: ReelsViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Section, MusicVideo>?
    
    // MARK: - UI
    
    private let titleView = UILabel().then {
        $0.text = "Lils MV"
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .white
    }
    
    private lazy var collectionView = {
        let cv = UICollectionView(frame: .zero,
                                  collectionViewLayout: createLayout())
        cv.delegate = self
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()
    
    // MARK: - Lifecycles
    
    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        updateSnapshot(mv: [])
    }
    
    override func bind() {
        super.bind()
        let input = ReelsViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in })
        let output = viewModel.transform(input)
        
        output.mvList.drive(with: self) { owner, mv in
            owner.updateSnapshot(mv: Array(mv))
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Layout
    
    override func configureHierarchy() {
        view.addSubview(collectionView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
    }
}

extension ReelsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ReelsCell else { return }
        DispatchQueue.main.async {
            cell.soundOn()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        tapImpact()
        guard let cell = cell as? ReelsCell else { return }
        DispatchQueue.main.async {
            cell.mute()
        }
    }
}

// MARK: - CollectionViewLayout

extension ReelsViewController {
    
    enum Section: CaseIterable {
        case main
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
    
    private func updateSnapshot(mv: [MusicVideo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MusicVideo>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(mv, toSection: .main)
        dataSource?.apply(snapshot)
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}






















