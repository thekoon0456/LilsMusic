//
//  MusicAPIManager.swift
//  FlowMusic
//
//  Created by Deokhun KIM on 3/15/24.
//

import Foundation
import MusicKit

final class MusicAPIManager {
    
    static let shared = MusicAPIManager()
    
    private init() { }
    
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
        let song = try await requestMVToSongCatalog(term: "\(item.artistName), \(item.title)")
        return song
    }
    
//    func MusicVideoToSong(_ item: MusicVideo) async throws -> Song? {
//        let song = try await requestSearchMVIDCatalog(id: item.id)
//        return song
//    }
    
    // MARK: - Charts
    
    func requestCatalogTop100Charts() async throws -> MusicItemCollection<Playlist> {
        let response = try await MusicCatalogChartsRequest(kinds: [MusicCatalogChartKind.dailyGlobalTop], types: [Playlist.self]).response()
        guard let charts = response.playlistCharts.first else { return [] }
        return charts.items
    }
    
    func requestCatalogMostPlayedCharts() async throws -> MusicItemCollection<Playlist> {
        guard let response = try await MusicPersonalRecommendationsRequest().response().recommendations.first else { return [] }
        let charts = response.playlists
        return charts
    }
    
    func requestCatalogCityTop25Charts() async throws -> MusicItemCollection<Playlist> {
        let response = try await MusicCatalogChartsRequest(kinds: [MusicCatalogChartKind.cityTop], types: [Playlist.self]).response()
        guard let charts = response.playlistCharts.first else { return [] }
        return charts.items
    }

    func requestCatalogSongCharts() async throws -> MusicItemCollection<Song> {
        let response = try await MusicCatalogChartsRequest(types: [Song.self]).response()
        guard let charts = response.songCharts.first else { return [] }
        return charts.items
    }
    
    //playlistCharts
    func requestCatalogPlaylistCharts() async throws -> MusicItemCollection<Playlist> {
        let response = try await MusicCatalogChartsRequest(types: [Playlist.self]).response()
        guard let charts = response.playlistCharts.first else { return [] }
        return charts.items
    }
    
    //albumCharts
    func requestCatalogAlbumCharts() async throws -> MusicItemCollection<Album> {
        let response = try await MusicCatalogChartsRequest(types: [Album.self]).response()
        guard let charts = response.albumCharts.first else { return [] }
        return charts.items
    }
    
    //mvCharts
    func requestCatalogMVCharts() async throws -> MusicItemCollection<MusicVideo> {
        let response = try await MusicCatalogChartsRequest(types: [MusicVideo.self]).response()
        guard let charts = response.musicVideoCharts.first else { return [] }
        return charts.items
    }
    
    // MARK: - Recommendation
    
    //
    func requestRecommendationAlbums() async throws -> MusicItemCollection<Album> {
        let response = try await MusicPersonalRecommendationsRequest().response()
        guard let recommendation = response.recommendations.first?.albums else { return [] }
        return recommendation
    }
    
    func requestRecommendationPlaylist() async throws -> MusicItemCollection<Playlist> {
        let response = try await MusicPersonalRecommendationsRequest().response()
        guard let recommendation = response.recommendations.first?.playlists else { return [] }
        return recommendation
    }
    
    func requestRecommendationStation() async throws -> MusicItemCollection<Station> {
        let response = try await MusicPersonalRecommendationsRequest().response()
        guard let recommendation = response.recommendations.first?.stations else { return [] }
        return recommendation
    }
    
    // MARK: - Search
    
    func requestSearchSongIDCatalog(id: MusicItemID?) async throws -> Song? {
        guard let id else { return nil }
        return try await MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: id).response().items.first
    }
    
    //MV -> Song. 제목과 가수 일치 안하면 nil 반환
    func requestMVToSongCatalog(term: String) async throws -> Song? {
        let songs = try await MusicCatalogSearchRequest(term: term, types: [Song.self]).response().songs
        let result = songs.filter { term.contains($0.title) && term.contains($0.artistName) }.first
        return result
    }
    
    //nil만 나옴..
    func requestSearchMVIDCatalog(id: MusicItemID?) async throws -> Song? {
        guard let id else { return nil }
        let response = try await MusicCatalogResourceRequest<MusicVideo>(matching: \.id, equalTo: id).response()
        guard let item = response.items.first else { return nil }
        let songs = try await item.with(.songs).songs
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
    
    // MARK: - RequestLibrary
    
    func requestPlaylist(ids: [String]) async throws -> MusicItemCollection<Track> {
        guard !ids.isEmpty else { return [] }
        let response = try await MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: setMusicItemID(ids)).response()
        let tracks = response.items.map { Track.song($0) }
        return MusicItemCollection(tracks)
    }
    
    func requestArtistList(ids: [String]) async throws -> MusicItemCollection<Artist> {
        guard !ids.isEmpty else { return [] }
        let response = try await MusicCatalogResourceRequest<Artist>(matching: \.id, memberOf: setMusicItemID(ids)).response()
        let artists = response.items
        return artists
    }
    
    func requestLikeList(ids: [String]) async throws -> MusicItemCollection<Track> {
        guard !ids.isEmpty else { return [] }
        let response = try await MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: setMusicItemID(ids)).response()
        let tracks = response.items.map { Track.song($0) }
        return MusicItemCollection(tracks)
    }
    
    func requestAlbumList(ids: [String]) async throws -> MusicItemCollection<Album> {
        guard !ids.isEmpty else { return [] }
        let response = try await MusicCatalogResourceRequest<Album>(matching: \.id, memberOf: setMusicItemID(ids)).response()
        let albums = response.items
        return albums
    }
    
    func requestRecentlyPlayed() async throws -> MusicItemCollection<Track> {
        return try await MusicRecentlyPlayedRequest<Track>().response().items
    }
    
    func setMusicItemID(_ ids: [String]) -> [MusicItemID] {
        ids.map { MusicItemID($0) }
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
