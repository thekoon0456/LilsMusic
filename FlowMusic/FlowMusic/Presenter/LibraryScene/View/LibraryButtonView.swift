//
//  LibraryButtonView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/19/24.
//

import UIKit

import RxSwift
import RxGesture
import SnapKit

final class LibraryButtonView: BaseView {
    
    // MARK: - Properties
    
    private let backView = UIView().then {
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    private lazy var iconImageView = UIImageView().then {
        $0.tintColor = .systemRed
        $0.contentMode = .scaleAspectFill
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.numberOfLines = 0
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemGray
    }
    
    private let descriptionLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 12)
    }
    
    var tap: Observable<Void> {
        return self.rx.tapGesture()
            .when(.recognized)
            .asObservable()
            .map { _ in return }
    }
    
    convenience init(imageName: String, title: String, subTitle: String, bgColor: UIColor) {
        self.init(frame: .zero)
        iconImageView.image = UIImage(systemName: imageName)
        titleLabel.text = title
        subtitleLabel.text = subTitle
//        descriptionLabel.text = "\(list.likeID.count)Songs"
//        backView.setGradient(startColor: bgColor.cgColor, endColor: bgColor.cgColor)
        backgroundColor = bgColor
        setGradient(startColor: bgColor.cgColor, endColor: bgColor.cgColor)
        isUserInteractionEnabled = true
        layer.cornerRadius = 10
        clipsToBounds = true
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        addSubview(backView)
        backView.addSubviews(iconImageView,
                             titleLabel,
                             subtitleLabel,
                             descriptionLabel)
    }
    
    override func configureLayout() {
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(8)
            make.size.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(backView.snp.top).offset(-8)
        }
    }
    
    override func configureView() {
        super.configureView()
//        addShadow()
    }
}
