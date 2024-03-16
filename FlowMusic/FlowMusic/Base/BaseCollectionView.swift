//
//  BaseCollectionView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/16/24.
//

import UIKit

import RxSwift

class BaseCollectionView: UICollectionView {
    
    // MARK: - Properties
    
    var disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
    }
    
    // MARK: - Helpers
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { }
    func bind() { }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
