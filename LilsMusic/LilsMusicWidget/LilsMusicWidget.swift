//
//  LilsMusicWidget.swift
//  LilsMusicWidget
//
//  Created by Deokhun KIM on 5/30/24.
//

import WidgetKit
import SwiftUI
import MusicKit

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> MusicEntry {
        let entry = MusicEntry(date: Date(), albumArt: nil, song: nil, artist: nil)
        return entry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MusicEntry) -> Void) {
        let entry = MusicEntry(date: Date(), albumArt: nil, song: nil, artist: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MusicEntry>) -> Void) {
        Task {
            let recentlyMusic = try? await MusicAPIManager.shared.requestRecentlyPlayed()
            
            var entries: [MusicEntry] = []
            
            if let recentlyPlayedMusic = recentlyMusic?.first {
                // Generate a timeline consisting of five entries an hour apart, starting from the current date.
                let currentDate = Date()
                for hourOffset in 0 ..< 5 {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    let entry = MusicEntry(date: entryDate,
                                           albumArt: recentlyPlayedMusic.artwork?.url(width: 500, height: 500),
                                           song: recentlyPlayedMusic.title,
                                           artist: recentlyPlayedMusic.artistName)
                    entries.append(entry)
                }
            }
            
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}

struct MusicEntry: TimelineEntry {
    let date: Date
    let albumArt: URL?
    let song: String?
    let artist: String?
}

struct LilsMusicWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            AsyncImage(url: entry.albumArt)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack {
                Spacer()
                Text(entry.song ?? "")
                Text(entry.artist ?? "")
            }
        }
    }
}

struct LilsMusicWidget: Widget {
    let kind: String = "LilsMusicWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                LilsMusicWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LilsMusicWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Lil's Music")
        .description("Add your Music")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

//#Preview {
//    LilsMusicWidget() as! any View
//}
