//
//  APIManager.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/11/24.
//

import Foundation

final class APIManager {
    
    static let shared = APIManager()
    
    private init() { }
    
    func getData(completion: @escaping ((Data) -> Void)) {
        
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://music.apple.com/kr/music-video/whats-my-name-feat-drake/1445826170?l=en-GB")!)) { data, response, error in
            if let error {
                print(error)
            }
            
            print(response)
            
            guard let data else { return }
            print(data)
            completion(data)
            
        }.resume()
    }
}
