//
//  ReelsViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import AVKit
import MusicKit
import UIKit

import RxCocoa
import RxSwift
import SnapKit

final class ReelsViewController: BaseViewController {
    
    // MARK: - Properties
    
    private let viewModel: ReelsViewModel
    private var dataSource: UICollectionViewDiffableDataSource<Section, MusicVideo>?
    private let playStatusSubject = BehaviorSubject<AVPlayer.TimeControlStatus>(value: .paused)
    
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
    
    private let playIconView = UIImageView().then {
        $0.image = UIImage(systemName: "play.circle")?.withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 44)))
        $0.contentMode = .scaleAspectFill
        $0.tintColor = .white
    }
    
    // MARK: - Lifecycles
    
    init(viewModel: ReelsViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource(status: .paused)
        updateSnapshot(mv: [])
        playStatusSubject.onNext(.paused)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        collectionView.visibleCells.forEach { cell in
//            guard let reelsCell = cell as? ReelsCell else { return }
//            reelsCell.mute()
//            reelsCell.pause()
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        collectionView.visibleCells.forEach { cell in
//            guard let reelsCell = cell as? ReelsCell else { return }
//            reelsCell.mute()
//            reelsCell.pause()
//        }
//    }
    
    override func bind() {
        super.bind()
        
        let input = ReelsViewModel.Input(viewWillAppear: self.rx.viewWillAppear.map { _ in })
        let output = viewModel.transform(input)
        
        output.mvList.drive(with: self) { owner, mv in
            owner.updateSnapshot(mv: Array(mv))
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.subscribe(with: self) { owner, indexPath in
            guard let currentStatus = try? owner.playStatusSubject.value() else { return }
            owner.updatePlayButton(status: currentStatus)
            owner.setPlayerStatus(status: currentStatus)
        }.disposed(by: disposeBag)
        
        playStatusSubject.subscribe(with: self) { owner, status in
            guard let mv = try? owner.viewModel.mvSubject.value() else { return }
            owner.configureDataSource(status: status)
            owner.updateSnapshot(mv: Array(mv))
            owner.updatePlayButton(status: status)
        }.disposed(by: disposeBag)
    }
    
    func setPlayerStatus(status: AVPlayer.TimeControlStatus) {
        switch status {
        case .paused:
            playStatusSubject.onNext(.waitingToPlayAtSpecifiedRate)
        default:
            playStatusSubject.onNext(.paused)
        }
    }
    
    func updatePlayButton(status: AVPlayer.TimeControlStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch status {
            case .paused:
                playIconView.isHidden = false
            default:
                playIconView.isHidden = true
            }
        }
    }
    
    func pausePlayState() {
        collectionView.visibleCells.forEach { cell in
            guard let reelsCell = cell as? ReelsCell else { return }
            reelsCell.mute()
            reelsCell.pause()
        }
    }
    
    func playPlayState() {
        collectionView.visibleCells.forEach { cell in
            guard let reelsCell = cell as? ReelsCell else { return }
            reelsCell.soundOn()
            reelsCell.play()
        }
    }
    
    // MARK: - Layout
    
    override func configureHierarchy() {
        view.addSubviews(collectionView, playIconView)
    }
    
    override func configureLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        
        playIconView.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }
    }
    
    override func configureView() {
        super.configureView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
    }
}

// MARK: - CollectionView Controller
//
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
    
    private func configureDataSource(status: AVPlayer.TimeControlStatus) {
        let cellRegistration = UICollectionView.CellRegistration<ReelsCell, MusicVideo> { cell, indexPath, itemIdentifier in
            cell.configureCell(itemIdentifier, status: status)
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






















