//
//  Observable.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/10/24.
//

import Foundation

final class Observable<T> {
    
    // MARK: - Properties
    
    typealias Listener = (T) -> Void
    
    private var listener: Listener?
    
    private var value: T {
        didSet {
            listener?(value)
        }
    }
    
    var currentValue: T {
        value
    }
    
    // MARK: - Lifecycles
    
    init(_ value: T) {
        self.value = value
    }
    
    // MARK: - Helpers
    
    func bind(listener: Listener?) {
        self.listener = listener
    }
    
    func onNext(_ value: T) {
        self.value = value
    }
}
