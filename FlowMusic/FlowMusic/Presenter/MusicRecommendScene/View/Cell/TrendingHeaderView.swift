//
//  TrendingHeaderView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/14/24.
//

import UIKit

import SnapKit

final class TrendingHeaderView: UICollectionReusableView {
    
    // MARK: - Properties
    
    static var identifier: String {
        return self.description()
    }
        
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 20)
        $0.textColor = .tintColor
    }
    
    // MARK: - Lifecycles
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureHierarchy()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configure
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
    }
    
    private func configureHierarchy() {
        addSubview(titleLabel)
    }
    
    private func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
}
