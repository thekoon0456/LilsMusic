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
    
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark)).then {
        $0.alpha = 0.3
    }
    
    private lazy var iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 16)
        $0.textColor = .bgColor
    }
    
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .bgColor
    }
    
    lazy var playButton = UIButton().then {
        let image = UIImage(systemName: "pause.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
        let selectedImage = UIImage(systemName: "play.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 36)))
        $0.setImage(image, for: .normal)
        $0.setImage(selectedImage, for: .selected)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    lazy var nextButton = UIButton().then {
        let image = UIImage(systemName: "forward.end.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
        $0.tapAnimation()
    }
    
    lazy var previousButton = UIButton().then {
        let image = UIImage(systemName: "backward.end.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 24)))
        $0.setImage(image, for: .normal)
        $0.tintColor = .bgColor
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
        iconImageView.kf.setImage(with: data.artwork?.url(width: 80, height: 80))
        setGradient(startColor: data.artwork?.backgroundColor,
                    endColor: data.artwork?.backgroundColor)
        titleLabel.text = data.title
        subtitleLabel.text = data.artistName
    }
    
    // MARK: - Configure
    
    override func configureHierarchy() {
        addSubviews(blurView, iconImageView, titleLabel, subtitleLabel,
                    previousButton, playButton, nextButton)
    }
    
    override func configureLayout() {
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
            make.width.equalTo(32)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalTo(playButton.snp.leading).offset(-16)
        }
        
        playButton.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalTo(nextButton.snp.leading).offset(-16)
        }
        
        nextButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-8)
        }
    }
    
    override func configureView() {
        super.configureView()
        layer.cornerRadius = 12
        clipsToBounds = true
    }
}

