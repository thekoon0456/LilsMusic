//
//  UserPlaylistRepository.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/13/24.
//

import Foundation

import RealmSwift

final class UserRepository<T: Object>: Repository {
    
    private let realm = try! Realm()
    
    //생성할때마다 옵셔널이 조금 번거롭네용..
//    init?() {
//        do {
//            self.realm = try Realm()
//        } catch {
//            print("realm 초기화 실패: \(error.localizedDescription)")
//            return nil
//        }
//    }
    
    func printURL() {
        print(realm.configuration.fileURL ?? "")
    }
    
    // MARK: - Create
    
    func createItem(_ item: T) {
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
    
    func fetch() -> Results<T> {
        return realm.objects(T.self)
    }
    
    func fetchArr() -> [T] {
        return Array(realm.objects(T.self))
    }
    
    // MARK: - Update
    
    func update(_ item: T) {
        do {
            try realm.write {
                realm.add(item, update: .modified)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updatePlaylist(_ item: UserPlaylist, id: String) {
        do {
            try realm.write {
                item.playlistID.append(id)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateArtist(_ item: UserArtistList, id: String) {
        do {
            try realm.write {
                item.artistID.append(id)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateUserLikeList(_ item: UserLikeList, id: String) {
        do {
            try realm.write {
                item.likeID.append(id)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateUserAlbumList(_ item: UserAlbumList, id: String) {
        do {
            try realm.write {
                item.albumID.append(id)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Delete
    
    func delete(_ item: T) {
        do {
            try realm.write {
                realm.delete(item)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAll(_ item: T) {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deletePlaylist(_ item: UserPlaylist, id: String) {
        do {
            try realm.write {
                if let index = item.playlistID.firstIndex(of: id) {
                    item.playlistID.remove(at: index)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteArtist(_ item: UserArtistList, id: String) {
        do {
            try realm.write {
                if let index = item.artistID.firstIndex(of: id) {
                    item.artistID.remove(at: index)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteUserLikeList(_ item: UserLikeList, id: String) {
        do {
            try realm.write {
                if let index = item.likeID.firstIndex(of: id) {
                    item.likeID.remove(at: index)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteUserAlbumList(_ item: UserAlbumList, id: String) {
        do {
            try realm.write {
                if let index = item.albumID.firstIndex(of: id) {
                    item.albumID.remove(at: index)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

