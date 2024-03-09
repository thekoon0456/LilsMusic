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
    
    private let player = MusicPlayer.shared
    private let request = MusicRequest.shared
    var album: Album
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
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
    
    init(album: Album) {
        self.album = album
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readyFadeInAnimation()
        loadDataAndUpdateUI()
    }
    
    func loadDataAndUpdateUI() {
        configureDataSource()
        
        Task {
            album = try await album.with([.tracks])
            updateSnapshot()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                updateUI(with: album)
                fadeInAnimation()
            }
        }
    }
    
    func updateUI(with album: Album) {
        artworkImageView.kf.setImage(with: album.artwork?.url(width: 200, height: 200))
        setGradient(startColor: album.artwork?.backgroundColor,
                    endColor: album.artwork?.backgroundColor)
        albumlabel.text = album.title
        artistlabel.text = album.artistName
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
            make.horizontalEdges.bottom.equalToSuperview()
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
        guard let track = (album.tracks?.map { $0 }) else { return }
        snapshot.appendItems(track, toSection: 1)
        dataSource?.apply(snapshot)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
}

// MARK: - Auth

extension MusicListViewController {
    
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        
        switch status {
        case .authorized:
            print("승인됨")
        default:
            moveToUserSetting()
            print("승인안됨. 재요청")
        }
    }
    
    private func moveToUserSetting() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "음악 접근 권한이 필요합니다.",
                                          message: "음악 라이브러리에 접근하기 위해서는 설정에서 권한을 허용해주세요",
                                          preferredStyle: .alert)
            
            let primaryButton = UIAlertAction(title: "설정으로 가기", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            let cancelButton = UIAlertAction(title: "취소", style: .default)
            
            alert.addAction(primaryButton)
            alert.addAction(cancelButton)
            
            navigationController?.present(alert, animated: true)
        }
    }
}
