//
//  Repository.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/13/24.
//

import Foundation

import RealmSwift

protocol Repository {
    associatedtype T: Object
    
    func createItem(_: T)
    func fetch() -> Results<T>
    func update(_: T)
    func delete(_: T)
    func deleteAll(_: T)
}
