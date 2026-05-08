import Foundation

/// Lightweight, pre-computed snapshot of port state for the desktop widget.
///
/// The main app builds this from its live watcher data and writes it to the
/// App Group shared container as JSON. The widget extension reads and
/// decodes it without touching IOKit.
public struct WidgetSnapshot: Codable, Equatable {
    public let ports: [PortEntry]
    public let timestamp: Date

    public init(ports: [PortEntry], timestamp: Date = Date()) {
        self.ports = ports
        self.timestamp = timestamp
    }

    /// One port's display-ready state. Every field is pre-computed by the
    /// main app so the widget just decodes and renders.
    public struct PortEntry: Codable, Equatable, Identifiable {
        /// Stable numeric ID from the underlying USBCPort. Using the
        /// display name would break SwiftUI if two ports share the same
        /// description string.
        public let id: UInt64

        public let portName: String
        public let status: Status
        public let headline: String
        public let subtitle: String
        /// First bullet from PortSummary, used in the large widget size.
        public let topBullet: String?
        /// SF Symbol name for the port's current state.
        public let iconName: String

        public init(
            id: UInt64,
            portName: String,
            status: Status,
            headline: String,
            subtitle: String,
            topBullet: String?,
            iconName: String
        ) {
            self.id = id
            self.portName = portName
            self.status = status
            self.headline = headline
            self.subtitle = subtitle
            self.topBullet = topBullet
            self.iconName = iconName
        }
    }

    /// Mirrors PortSummary.Status but Codable. The widget extension maps
    /// this to colors independently (no SwiftUI in WhatCableCore).
    public enum Status: String, Codable {
        case empty
        case charging
        case dataDevice
        case thunderboltCable
        case displayCable
        case unknown
    }
}

// MARK: - App Group constants

extension WidgetSnapshot {
    /// App Group suite name shared between the main app and widget extension.
    public static let appGroupID = "group.uk.whatcable.whatcable"

    /// UserDefaults key for the encoded snapshot blob.
    public static let defaultsKey = "widgetSnapshot"
}

// MARK: - Convenience builders

extension WidgetSnapshot.Status {
    /// Convert from the existing PortSummary.Status enum.
    public init(from summary: PortSummary.Status) {
        switch summary {
        case .empty: self = .empty
        case .charging: self = .charging
        case .dataDevice: self = .dataDevice
        case .thunderboltCable: self = .thunderboltCable
        case .displayCable: self = .displayCable
        case .unknown: self = .unknown
        }
    }
}

extension WidgetSnapshot.Status {
    /// SF Symbol name for this status. Matches the icon mapping in
    /// PortSummary+UI.swift so the widget and main app show the same icons.
    public var iconName: String {
        switch self {
        case .empty: return "powerplug"
        case .charging: return "bolt.fill"
        case .dataDevice: return "cable.connector"
        case .thunderboltCable: return "bolt.horizontal.fill"
        case .displayCable: return "display"
        case .unknown: return "questionmark.circle"
        }
    }
}
