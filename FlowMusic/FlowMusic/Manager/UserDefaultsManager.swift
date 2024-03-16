//
//  UserDefaultsManager.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/15/24.
//

import Foundation

//반복은 기본 설정, 셔플은 기본설정 아님

final class UserDefaultsManager {
    
    static let shared = UserDefaultsManager()
    
    private init() { }
    
    @UserDefault(key: UserSetting.key, defaultValue: UserSetting(isShuffled: false,
                                                                 repeatMode: .all))
    var userSetting: UserSetting
}

@propertyWrapper
struct UserDefault<T: Codable> {
    private var key: String
    private var defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            if let savedData = UserDefaults.standard.object(forKey: key) as? Data {
                let decoder = JSONDecoder()
                if let loadedData = try? decoder.decode(T.self, from: savedData) {
                    return loadedData
                }
            }
            
            return defaultValue
        }
        set {
            let encoder = JSONEncoder()
            if let encodedData = try? encoder.encode(newValue) {
                UserDefaults.standard.set(encodedData, forKey: key)
            }
        }
    }
}


