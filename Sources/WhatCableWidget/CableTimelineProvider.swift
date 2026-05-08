import Foundation
import WidgetKit
import WhatCableCore

/// Reads the latest WidgetSnapshot from the App Group shared container
/// and builds a single-entry timeline. The main app pushes reloads via
/// WidgetCenter.reloadAllTimelines() whenever cable state changes.
///
/// A fallback 60-second refresh policy catches the case where the main
/// app quits or crashes and stops pushing reloads. If the snapshot is
/// older than 5 minutes, we treat it as stale and show the empty state.
struct CableTimelineProvider: TimelineProvider {
    /// Snapshots older than this are treated as stale (main app not running).
    private let staleAfter: TimeInterval = 5 * 60
    typealias Entry = CableWidgetEntry

    /// Shown briefly while the widget loads for the first time.
    func placeholder(in context: Context) -> CableWidgetEntry {
        CableWidgetEntry.placeholder
    }

    /// Quick snapshot for the widget gallery preview.
    func getSnapshot(in context: Context, completion: @escaping (CableWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(currentEntry())
        }
    }

    /// The real timeline. Primary updates come from the main app calling
    /// reloadAllTimelines(). The 60-second fallback catches the case where
    /// the app stops running, so stale data eventually falls to empty state.
    func getTimeline(in context: Context, completion: @escaping (Timeline<CableWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let timeline = Timeline(
            entries: [entry],
            policy: .after(Date().addingTimeInterval(60))
        )
        completion(timeline)
    }

    // MARK: - Read from App Group

    private func currentEntry() -> CableWidgetEntry {
        guard let url = WidgetSnapshot.sharedFileURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              Date().timeIntervalSince(snapshot.timestamp) <= staleAfter else {
            return CableWidgetEntry(date: Date(), snapshot: nil)
        }
        return CableWidgetEntry(date: snapshot.timestamp, snapshot: snapshot)
    }
}

/// Timeline entry wrapping a WidgetSnapshot. A nil snapshot means the
/// main app hasn't written any data yet (first launch, or app not running).
struct CableWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    static let placeholder = CableWidgetEntry(
        date: Date(),
        snapshot: WidgetSnapshot(ports: [
            .init(
                id: 1,
                portName: "USB-C Port 1",
                status: .thunderboltCable,
                headline: "Thunderbolt / USB4",
                subtitle: "Supports high-speed data, video, smart cable.",
                topBullet: "Linked at up to 40 Gb/s x 2",
                iconName: "bolt.horizontal.fill"
            ),
            .init(
                id: 2,
                portName: "USB-C Port 2",
                status: .charging,
                headline: "Charging - 96W charger",
                subtitle: "Power is flowing. No data connection.",
                topBullet: "Charger advertises up to 96W",
                iconName: "bolt.fill"
            ),
            .init(
                id: 3,
                portName: "USB-C Port 3",
                status: .empty,
                headline: "Nothing connected",
                subtitle: "Plug a cable in to see what it can do.",
                topBullet: nil,
                iconName: "powerplug"
            ),
        ])
    )
}
