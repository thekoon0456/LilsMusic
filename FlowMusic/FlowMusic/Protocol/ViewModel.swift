//
//  ViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import RxSwift

protocol ViewModel: AnyObject {
    
    associatedtype Input
    associatedtype Output
    
    var disposeBag: DisposeBag { get }

    func transform(_ input: Input) -> Output
}
