//
//  PlaylistMenuButton.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/17/24.
//

import UIKit

import RxCocoa
import RxSwift

final class FMPlaylistButton: UIButton {
    
    // MARK: - Properties
    
    let menuSelectionSubject = PublishSubject<String>()
    private let disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init(menus: [String]) {
        super.init(frame: .zero)
        
        configureUI(menus: menus)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func configureUI(menus: [String]) {
        setImage(UIImage(systemName: FMDesign.Icon.plus.name), for: .normal)
        tintColor = FMDesign.Color.tintColor.color
        showsMenuAsPrimaryAction = true
        menu = UIMenu(children: menus.map { title in
            UIAction(title: title) { [weak self] _ in
                guard let self else { return }
                menuSelectionSubject.onNext(title)
            }
        })
    }
}
