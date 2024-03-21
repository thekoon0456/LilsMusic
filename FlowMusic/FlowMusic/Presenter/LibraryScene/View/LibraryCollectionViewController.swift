//
//  LibraryCollectionViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/21/24.
//

import MusicKit
import UIKit

final class LibraryCollectionViewController: UICollectionViewController {
    
    var results: [Track] = []
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MusicListCell.identifier, for: indexPath) as? MusicListCell else { return UICollectionViewCell() }
        cell.configureCell(results[indexPath.item])
        return cell
    }
    
}
