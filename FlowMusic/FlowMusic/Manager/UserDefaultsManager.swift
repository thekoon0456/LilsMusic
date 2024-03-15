//
//  UserDefaultsManager.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/15/24.
//

import Foundation

//반복은 기본 설정, 셔플은 기본설정 아님

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    var container: UserDefaults = .standard

    var wrappedValue: T {
        get {
            return container.object(forKey: key) as? T ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    @UserDefault(key: "isRepeat", defaultValue: true)
    var isRepeat: Bool

    @UserDefault(key: "isShuffle", defaultValue: false)
    var isShuffle: Bool
}
