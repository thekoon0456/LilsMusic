//
//  LilsMusicWidget.swift
//  LilsMusicWidget
//
//  Created by Deokhun KIM on 5/30/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MusicEntry {
        return MusicEntry(date: Date(),
                          artwork: nil,
                          song: nil,
                          singer: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MusicEntry) -> ()) {
        let entry = MusicEntry(date: Date(),
                               artwork: nil,
                               song: nil,
                               singer: nil)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let recentlyPlayedMusic = try? await MusicAPIManager.shared.requestRecentlyPlayed()
            
            if let recentlyPlayedMusic = recentlyPlayedMusic?.first {
                var entries: [MusicEntry] = []
                
                let currentDate = Date()
                for hourOffset in 0 ..< 1 {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    let entry = MusicEntry(date: entryDate,
                                           artwork: recentlyPlayedMusic.artwork?.url(width: 800, height: 800),
                                           song: recentlyPlayedMusic.title,
                                           singer: recentlyPlayedMusic.artistName)
                    entries.append(entry)
                }
                
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            }
        }
    }
}

struct MusicEntry: TimelineEntry {
    let date: Date
    let artwork: URL?
    let song: String?
    let singer: String?
}

struct LilsMusicWidgetEntryView : View {
    
    @State private var isImageLoaded = false
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                Text(entry.song ?? "")
                    .font(.footnote)
                    .foregroundColor(.white)
                Text(entry.singer ?? "Play Your Music")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .shadow(color: .black, radius: 2, x: 1, y: 1)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 5)
        .background {
            AsyncImage(url: entry.artwork) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        isImageLoaded = true
                        WidgetCenter.shared.reloadAllTimelines()
                    }
            } placeholder: {
                Image(uiImage: UIImage(named: "lil") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
        .description("Play your Music")
        .contentMarginsDisabled()
    }
}

#Preview(body: {
let imageURL = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/cf/97/05/cf970525-a2fd-a7e3-2812-0f9c3f3d2c33/888735947551.png/600x600bb.jpg")

   return LilsMusicWidgetEntryView(entry: MusicEntry(date: Date(),
                                               artwork: nil,
                                               song: nil,
                                               singer: nil))
})
