//
//  MVRepository.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/12/24.
//

import Foundation
import MusicKit

final class MVRepository {
    
    static let shared = MVRepository()
    private let musicRequest = MusicRequest.shared
    
    private init() { }
    
    var musicVideos: [MusicItemCollection<MusicVideo>]?
    
    var videoURLs: [URL?]?
    
    var cachedVideoURLs: [URL] = []
    
    func fetchTodayMVURL(index: Int) async throws {
        print(#function)
        musicVideos = try await musicRequest.requestCatalogMVCharts()
        videoURLs = musicVideos?[index].map { $0.previewAssets?.first?.url }
//        return musicVideos?[index].map { $0.previewAssets?.first?.hlsURL }
        print(musicVideos)
        print(videoURLs)
    }
    
    func downloadInitialVideos(videoURLs: [URL?]?) {
        guard let videoURLs else { return }
        let initialURLs = Array(videoURLs)
        for url in initialURLs {
            downloadVideoIfNotCached(for: url) { result in
                switch result {
                case .success(let success):
                    print("캐싱 성공")
                    self.cachedVideoURLs.append(success)
                case .failure(let failure):
                    print(failure)
                }
            }
        }
    }
    
    func downloadVideoIfNotCached(for url: URL?, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url else { return }
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cachedUrl = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        
        // 이미 캐시되어 있다면, 바로 콜백을 호출합니다.
        if fileManager.fileExists(atPath: cachedUrl.path) {
            completion(.success(cachedUrl))
            return
        }
        
        // 캐시되어 있지 않다면, URL 세션을 사용하여 동영상을 다운로드합니다.
        let downloadTask = URLSession.shared.downloadTask(with: url) { tempLocalUrl, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let tempLocalUrl = tempLocalUrl else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "DownloadError", code: -1, userInfo: nil)))
                }
                return
            }
            
            do {
                // 다운로드된 파일을 캐시 디렉터리로 이동합니다.
                try fileManager.moveItem(at: tempLocalUrl, to: cachedUrl)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    completion(.success(cachedUrl))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        downloadTask.resume()
    }
}
