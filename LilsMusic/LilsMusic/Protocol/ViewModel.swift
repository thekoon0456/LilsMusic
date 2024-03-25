//
//  ViewModel.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import RxSwift

protocol ViewModel: AnyObject {
    
    associatedtype Input
    associatedtype Output
    
    var disposeBag: DisposeBag { get }

    func transform(_ input: Input) -> Output
}

extension ViewModel {
    
    func tapImpact() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }
}
