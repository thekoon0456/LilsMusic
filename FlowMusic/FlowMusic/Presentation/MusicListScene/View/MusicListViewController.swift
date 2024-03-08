//
//  MusicListViewController.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/8/24.
//

import UIKit
import MusicKit

final class MusicListViewController: BaseViewController {
    
    private let player = MusicPlayer.shared
    private let request = MusicRequest.shared
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        Task {
            await requestMusicAuthorization()
            //음악 요청
            let arr = try await request.requestCatalogAlbumCharts()
            print(arr)
            let arr2 = try await request.requestCatalogSongCharts()
            print(arr2)
        }
    }
    
}

extension MusicListViewController {
    
    func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        
        switch status {
        case .authorized:
            print("승인됨")
        default:
            moveToUserSetting()
            print("승인안됨. 재요청")
        }
    }
    
    private func moveToUserSetting() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "음악 접근 권한이 필요합니다.",
                                          message: "음악 라이브러리에 접근하기 위해서는 설정에서 권한을 허용해주세요",
                                          preferredStyle: .alert)
            
            let primaryButton = UIAlertAction(title: "설정으로 가기", style: .default) { _ in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            let cancelButton = UIAlertAction(title: "취소", style: .default)
            
            alert.addAction(primaryButton)
            alert.addAction(cancelButton)
            
            navigationController?.present(alert, animated: true)
        }
    }
}
