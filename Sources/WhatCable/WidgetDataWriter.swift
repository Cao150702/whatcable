import Foundation
import Combine
import WidgetKit
import os.log
import WhatCableCore
import WhatCableDarwinBackend

/// Writes a pre-computed WidgetSnapshot to the App Group shared container
/// whenever cable state changes, then tells WidgetKit to refresh.
///
/// Owns its own set of watchers so it runs independently of the UI.
/// Mirrors the pattern used by NotificationManager: watchers start at
/// app launch and keep running even when the popover is closed.
@MainActor
final class WidgetDataWriter {
    static let shared = WidgetDataWriter()

    private nonisolated static let log = Logger(
        subsystem: "uk.whatcable.whatcable",
        category: "widget-data"
    )

    // Own watcher instances, independent of the UI's watchers.
    private let portWatcher = USBCPortWatcher()
    private let deviceWatcher = USBWatcher()
    private let powerWatcher = PowerSourceWatcher()
    private let pdWatcher = PDIdentityWatcher()
    private let tbWatcher = ThunderboltWatcher()

    private var cancellables = Set<AnyCancellable>()
    private var writeTask: Task<Void, Never>?
    private var lastSnapshot: WidgetSnapshot?
    private var isStarted = false

    private init() {}

    func start() {
        guard !isStarted else { return }
        isStarted = true
        Self.log.debug("WidgetDataWriter starting (sharedFileURL: \(WidgetSnapshot.sharedFileURL?.path ?? "nil"))")
        portWatcher.start()
        deviceWatcher.start()
        powerWatcher.start()
        pdWatcher.start()
        tbWatcher.start()

        // Write an initial snapshot once watchers have had a tick to populate.
        DispatchQueue.main.async { [weak self] in
            self?.scheduleWrite()
        }

        // Watch all five signals. A single cable plug can fire several of
        // these within a few ms, so scheduleWrite() debounces into one write.
        portWatcher.$ports
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleWrite() }
            .store(in: &cancellables)

        deviceWatcher.$devices
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleWrite() }
            .store(in: &cancellables)

        powerWatcher.$sources
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleWrite() }
            .store(in: &cancellables)

        pdWatcher.$identities
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleWrite() }
            .store(in: &cancellables)

        tbWatcher.$switches
            .dropFirst()
            .sink { [weak self] _ in self?.scheduleWrite() }
            .store(in: &cancellables)
    }

    /// Debounced write. Cancels any pending write and waits 200ms for
    /// additional watcher updates to settle before encoding and writing.
    /// Mirrors the debounce pattern in ContentView.scheduleLivePortRefresh().
    private func scheduleWrite() {
        writeTask?.cancel()
        writeTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard !Task.isCancelled else { return }

            // Also refresh the port watcher to pick up property changes
            // that don't fire match notifications (same reason ContentView
            // polls ports on a timer).
            portWatcher.refresh()

            let snapshot = buildSnapshot()

            // Skip the write if the port data hasn't changed. Compare
            // ports only, not the timestamp, otherwise every snapshot
            // looks different and the dedup is useless.
            if snapshot.ports == lastSnapshot?.ports { return }

            // Only update lastSnapshot after a confirmed write. If the
            // write fails (missing container, encoding error), we want
            // the next change to retry rather than silently deduping.
            guard writeToDefaults(snapshot) else { return }
            lastSnapshot = snapshot

            // Tell WidgetKit to reload. This is a no-op when no widgets
            // are installed, so it's safe to call unconditionally.
            WidgetCenter.shared.reloadAllTimelines()

            Self.log.debug("Widget snapshot written: \(snapshot.ports.count) ports")
        }
    }

    private func buildSnapshot() -> WidgetSnapshot {
        let entries: [WidgetSnapshot.PortEntry] = portWatcher.ports.map { port in
            let devices = port.matchingDevices(from: deviceWatcher.devices)
            let sources = powerWatcher.sources(for: port)
            let identities = pdWatcher.identities(for: port)

            let isLive = WhatCableCore.isPortLive(
                port: port,
                powerSources: sources,
                identities: identities,
                matchingDevices: devices
            )

            let summary = PortSummary(
                port: port,
                sources: sources,
                identities: identities,
                devices: devices,
                thunderboltSwitches: tbWatcher.switches,
                isConnectedOverride: isLive
            )

            let status = WidgetSnapshot.Status(from: summary.status)

            return WidgetSnapshot.PortEntry(
                id: port.id,
                portName: port.portDescription ?? port.serviceName,
                status: status,
                headline: summary.headline,
                subtitle: summary.subtitle,
                topBullet: summary.bullets.first,
                iconName: status.iconName
            )
        }

        return WidgetSnapshot(ports: entries)
    }

    @discardableResult
    private func writeToDefaults(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = WidgetSnapshot.sharedFileURL else {
            Self.log.error("Failed to resolve App Group container URL")
            return false
        }

        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            Self.log.error("Failed to write widget snapshot: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
