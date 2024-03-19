//
//  BaseView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

import RxSwift

class BaseView: UIView {
    
    // MARK: - Properties
    
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
