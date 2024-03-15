//
//  BaseViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit

import RxSwift

class BaseViewController: UIViewController {
    
    // MARK: - Properties
    
    var disposeBag = DisposeBag()
    
    // MARK: - Lifecycles
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
        setDismissGesture()
    }
    
    // MARK: - Helpers
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { view.backgroundColor = .systemBackground }
    func bind() { }
    func setDismissGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanModalView))
        view.addGestureRecognizer(panGesture)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
}

extension BaseViewController {
    
    @objc func didPanModalView(sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == .began {
            initialTouchPoint = touchPoint
        } else if sender.state == .changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == .ended || sender.state == .cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}
