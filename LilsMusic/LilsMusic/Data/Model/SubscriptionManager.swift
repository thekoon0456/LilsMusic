//
//  SubscriptionManager.swift
//  LilsMusic
//
//  Created by Deokhun KIM on 3/31/24.
//

import Foundation
import MusicKit
import StoreKit

final class SubscriptionManager {
    
    static let shared = SubscriptionManager()
    
    private init() { }
    
    func checkAppleMusicSubscriptionEligibility(completion: @escaping (Bool) -> Void) {
        let controller = SKCloudServiceController()
        
        controller.requestCapabilities { capabilities, error in
            if let error {
                print(error.localizedDescription)
                return
            }
            
            if capabilities.contains(.musicCatalogSubscriptionEligible) && !capabilities.contains(.musicCatalogPlayback) {
                completion(false)
                return
            } else {
                completion(true)
                return
            }
        }
    }
}
