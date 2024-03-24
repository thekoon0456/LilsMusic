//
//  MiniPlayerView.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/16/24.
//

import UIKit
import MusicKit

import Kingfisher
import RxGesture
import RxCocoa
import RxSwift

final class MiniPlayerView: BaseView {
    
    // MARK: - Properties
    
    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 14)
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .lightGray
    }
    
    lazy var playButton = UIButton().then {
        $0.setImage(UIImage(systemName: "pause.circle.fill"), for: .normal)
        $0.setImage(UIImage(systemName: "play.circle.fill"), for: .selected)
        $0.contentVerticalAlignment = .fill
        $0.contentHorizontalAlignment = .fill
        $0.tintColor = .tintColor
//        $0.addShadow()
        $0.tapAnimation()
    }
    
    lazy var nextButton = UIButton().then {
        $0.setImage(UIImage(systemName: "forward.end.circle"), for: .normal)
        $0.contentVerticalAlignment = .center
        $0.contentHorizontalAlignment = .center
        $0.tintColor = .tintColor
//        $0.addShadow()
        $0.tapAnimation()
    }
    
    lazy var previousButton = UIButton().then {
        $0.setImage(UIImage(systemName: "backward.end.circle"), for: .normal)
        $0.contentVerticalAlignment = .center
        $0.contentHorizontalAlignment = .center
        $0.tintColor = .tintColor
//        $0.addShadow()
        $0.tapAnimation()
    }
    
    var tap: Observable<Void> {
        return self.rx.tapGesture()
            .when(.recognized)
            .asObservable()
            .map { _ in return }
    }
    
    // MARK: - Helpers
    
    func configureView(_ data: Track) {
        guard let bgColor = data.artwork?.backgroundColor else { return }
        iconImageView.kf.setImage(with: data.artwork?.url(width: 40, height: 40))
        backgroundColor = UIColor(cgColor: bgColor)
        titleLabel.text = data.title
        subtitleLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        addSubviews(iconImageView, titleLabel, subtitleLabel, previousButton, playButton, nextButton)
    }
    
    override func configureLayout() {
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.top)
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(previousButton.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.lessThanOrEqualTo(previousButton.snp.leading).offset(-8)
            make.bottom.equalTo(iconImageView.snp.bottom)
        }
        
        previousButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(playButton.snp.leading).offset(-20)
        }
        
        playButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(nextButton.snp.leading).offset(-20)
        }
        
        nextButton.snp.makeConstraints { make in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    override func configureView() {
        super.configureView()
//        addShadow()
//        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        clipsToBounds = true
//        alpha = 0.95
    }
}

