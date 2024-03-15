//
//  MusicRepository.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/15/24.
//

import Foundation
import MusicKit

final class MusicRepository {
    
    // MARK: - RequestNextBatch
    
    func requestNextBatch<T: MusicItem>(items: MusicItemCollection<T>) async throws -> MusicItemCollection<T>? {
        let hasNextBatch = items.hasNextBatch
        return hasNextBatch ? try await items.nextBatch() : nil
    }
    
    // MARK: - Catalog
    
    // MARK: - collectionToTracks
    
    func albumToTracks(_ item: Album) async throws -> MusicItemCollection<Track>? {
        try await item.with(.tracks).tracks
    }
    
    func playlistToTracks(_ item: Playlist) async throws -> MusicItemCollection<Track>? {
        try await item.with(.tracks).tracks
    }
    
    func MusicVideoToSong(_ item: MusicVideo) async throws -> Song? {
        let song = try await requestSearchSongCatalog(term: "\(item.title) \(item.artistName)")
        return song.first
    }
    
    // MARK: - Charts

    func requestCatalogSongCharts() async throws -> MusicItemCollection<Song> {
        print(#function)
        let response = try await MusicCatalogChartsRequest(types: [Song.self]).response()
        guard let charts = response.songCharts.first else { return [] }
        print(charts)
        return charts.items
    }
    
    //playlistCharts
    func requestCatalogPlaylistCharts() async throws -> MusicItemCollection<Playlist> {
        print(#function)
        let response = try await MusicCatalogChartsRequest(types: [Playlist.self]).response()
        guard let charts = response.playlistCharts.first else { return [] }
        return charts.items
    }
    
    //albumCharts
    func requestCatalogAlbumCharts() async throws -> MusicItemCollection<Album> {
        print(#function)
        let response = try await MusicCatalogChartsRequest(types: [Album.self]).response()
        guard let charts = response.albumCharts.first else { return [] }
        return charts.items
    }

    
    
    func requestCatalogMVCharts(index: Int) async throws -> MusicItemCollection<MusicVideo> {
        try await MusicCatalogChartsRequest(types: [MusicVideo.self]).response().musicVideoCharts.map { $0.items }[index]
    }
    
    // MARK: - Search
    
    func requestSearchSongIDCatalog(id: MusicItemID?) async throws -> Song? {
        guard let id else { return nil }
        return try await MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: id).response().items.first
    }
    
    func requestSearchMVIDCatalog(id: MusicItemID?) async throws -> Song? {
        guard let id else { return nil }
        let response = try await MusicCatalogResourceRequest<MusicVideo>(matching: \.id, equalTo: id).response()
        let items = response.items
        let songs = items.first?.songs
        let song = songs?.first
        return song
    }
    
    func requestSearchArtistCatalog(term: String) async throws -> MusicItemCollection<Artist> {
        try await MusicCatalogSearchRequest(term: term, types: [Artist.self]).response().artists
    }
    
    func requestSearchAlbumCatalog(term: String) async throws -> MusicItemCollection<Album> {
        try await MusicCatalogSearchRequest(term: term, types: [Album.self]).response().albums
    }
    
    func requestSearchSongCatalog(term: String) async throws -> MusicItemCollection<Song> {
        try await MusicCatalogSearchRequest(term: term, types: [Song.self]).response().songs
    }
    
    func requestSearchPlaylistCatalog(term: String) async throws -> MusicItemCollection<Playlist> {
        try await MusicCatalogSearchRequest(term: term, types: [Playlist.self]).response().playlists
    }
    
    func requestSearchStationCatalog(term: String) async throws -> MusicItemCollection<Station> {
        try await MusicCatalogSearchRequest(term: term, types: [Station.self]).response().stations
    }
    
    func requestSearchMusicVideoCatalog(term: String) async throws -> MusicItemCollection<MusicVideo> {
        try await MusicCatalogSearchRequest(term: term, types: [MusicVideo.self]).response().musicVideos
    }
    
    func requestCatalogTopResults(term: String) async throws -> MusicItemCollection<MusicCatalogSearchResponse.TopResult> {
        // 검색 가능한 타입을 직접 명시하거나, 검색 로직을 조정
        try await MusicCatalogSearchSuggestionsRequest(term: term,
                                                       includingTopResultsOfTypes: [Song.self,
                                                                                    Album.self,
                                                                                    Playlist.self]).response().topResults
    }
    
    //    func requestSearchCuratorCatalog<T: MusicItem>(term: String) async throws -> MusicCatalogSearchResponse<T> {
    //        try await MusicCatalogSearchRequest(term: term, types: [T.self]).response()
    //    }
    //
    //    func requestSearchArtistCatalog(term: String) async throws -> MusicItemCollection<Artist> {
    //        try await MusicCatalogSearchRequest(term: term, types: [Artist.self]).response().artists
    //    }
    //
    //    func requestCatalogSong<T: MusicCatalogSearchable>(term: String) async throws -> MusicItemCollection<MusicCatalogSearchResponse.TopResult> {
    //        return try await MusicCatalogSearchSuggestionsRequest(term: term, includingTopResultsOfTypes: [T.self]).response().topResults
    //    }
    //
    //    MusicItemCollection<>
    //
    //    func requestCatalogTrack() async throws -> MusicItemCollection<Track> {
    //        try await MusicCatalogResourceRequest(matching: KeyPath<(FilterableMusicItem & Decodable).FilterType, Value>, memberOf: <#T##[Value]#>)<Track>().response().items
    //    }
    //
    //    func requestCatalogGenre() async throws -> MusicItemCollection<Genre> {
    //        try await MusicCatalogResourceRequest(matching: KeyPath<(FilterableMusicItem & Decodable).FilterType, Value>, equalTo: <#T##Value#>)<Genre>().response().items
    //    }
}

// MARK: - Library Request

extension MusicRepository {
    
    func requestLibraryAlbum() async throws -> MusicItemCollection<Album> {
        try await MusicLibraryRequest<Album>().response().items
    }
    
    func requestLibraryArtist() async throws -> MusicItemCollection<Artist> {
        try await MusicLibraryRequest<Artist>().response().items
    }
    
    func requestLibrarySong() async throws -> MusicItemCollection<Song> {
        try await MusicLibraryRequest<Song>().response().items
    }
    
    func requestLibraryTrack() async throws -> MusicItemCollection<Track> {
        try await MusicLibraryRequest<Track>().response().items
    }
    
    func requestLibraryGenre() async throws -> MusicItemCollection<Genre> {
        try await MusicLibraryRequest<Genre>().response().items
    }
    
    func requestLibraryMV() async throws -> MusicItemCollection<MusicVideo> {
        try await MusicLibraryRequest<MusicVideo>().response().items
    }
}
