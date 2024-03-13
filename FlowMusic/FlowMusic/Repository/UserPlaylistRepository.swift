//
//  UserPlaylistRepository.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/13/24.
//

import Foundation

import RealmSwift

final class UserPlaylistRepository: Repository {
    
    private let realm = try! Realm()
    
    func printURL() {
        print(realm.configuration.fileURL ?? "")
    }
    
    // MARK: - Create
    
    func createItem(_ item: UserPlaylist) {
        do {
            try realm.write {
                realm.add(item)
                print("DEBUG: realm Create")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Read
    
    func fetch() -> Results<UserPlaylist> {
        return realm.objects(UserPlaylist.self)
    }
    
    func fetchArr() -> [UserPlaylist] {
        return Array(realm.objects(UserPlaylist.self))
    }
    
    // MARK: - Update
    
    func update(_ item: UserPlaylist) {
        do {
            try realm.write {
                realm.add(item, update: .modified)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePlaylist(_ item: UserPlaylist, playlistID: String) {
        do {
            try realm.write {
                item.playlistID.append(playlistID)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Delete
    
    func delete(_ item: UserPlaylist) {
        do {
            try realm.write {
                realm.delete(item)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAll(_ item: UserPlaylist) {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

