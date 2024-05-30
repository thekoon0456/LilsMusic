//
//  LilsMusicWidget.swift
//  LilsMusicWidget
//
//  Created by Deokhun KIM on 5/30/24.
//

import WidgetKit
import SwiftUI
import Kingfisher

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
                for hourOffset in 0 ..< 5 {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    let entry = MusicEntry(date: entryDate,
                                           artwork: recentlyPlayedMusic.artwork?.url(width: 600, height: 600),
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
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            KFImage(entry.artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
            
            VStack {
                Spacer()
                Text(entry.song ?? "최근 노래가 없습니다.")
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 10)
                Text(entry.singer ?? "노래를 재생해주세요.")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 10)
            }
            .padding(.bottom, 5)
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

//#Preview(as: .systemSmall) {
//    LilsMusicWidget()
//} timeline: {
//    SimpleEntry(date: .now, emoji: "😀")
//    SimpleEntry(date: .now, emoji: "🤩")
//}

//#Preview(body: {
//let imageURL = URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/cf/97/05/cf970525-a2fd-a7e3-2812-0f9c3f3d2c33/888735947551.png/600x600bb.jpg")

//    LilsMusicWidgetEntryView(entry: MusicEntry(date: Date(),
//                                               artwork: nil,
//                                               song: nil,
//                                               singer: nil))
//})
