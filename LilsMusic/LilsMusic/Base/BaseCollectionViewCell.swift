//
//  BaseCollectionViewCell.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

import RxSwift

class BaseCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static var identifier: String {
        return self.description()
    }

    var disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
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
