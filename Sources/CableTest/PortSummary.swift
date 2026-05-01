import Foundation
import SwiftUI

/// Plain-English interpretation of a USBCPort's raw IOKit data.
struct PortSummary {
    enum Status {
        case empty
        case charging
        case dataDevice
        case thunderboltCable
        case displayCable
        case unknown
    }

    let status: Status
    let headline: String
    let subtitle: String
    let bullets: [String]

    var icon: String {
        switch status {
        case .empty: return "powerplug"
        case .charging: return "bolt.fill"
        case .dataDevice: return "cable.connector"
        case .thunderboltCable: return "bolt.horizontal.fill"
        case .displayCable: return "display"
        case .unknown: return "questionmark.circle"
        }
    }

    var iconColor: Color {
        switch status {
        case .empty: return .secondary
        case .charging: return .yellow
        case .dataDevice: return .blue
        case .thunderboltCable: return .purple
        case .displayCable: return .teal
        case .unknown: return .orange
        }
    }
}

extension PortSummary {
    init(port: USBCPort) {
        let connected = port.connectionActive == true
        let active = port.transportsActive
        let supported = port.transportsSupported
        let hasUSB3 = active.contains("USB3") || port.superSpeedActive == true
        let hasUSB2 = active.contains("USB2")
        let hasTB = active.contains("CIO") // Thunderbolt = Converged I/O
        let hasDP = active.contains("DisplayPort")
        let hasEmarker = port.activeCable == true
        let portLabel = port.portDescription ?? port.serviceName

        if !connected {
            self.status = .empty
            self.headline = "Nothing connected"
            self.subtitle = "Plug a cable into \(portLabel) to see what it can do."
            self.bullets = []
            return
        }

        var bullets: [String] = []

        // Speed
        if hasTB {
            bullets.append("Thunderbolt / USB4 link active")
        } else if hasUSB3 {
            bullets.append("SuperSpeed USB (5 Gbps or faster)")
        } else if hasUSB2 {
            bullets.append("USB 2.0 only (480 Mbps) — no high-speed data")
        }

        if hasDP {
            bullets.append("Carrying DisplayPort video")
        }

        // E-marker
        if hasEmarker {
            bullets.append("Cable has an e-marker chip (advertises its capabilities)")
        } else if !active.isEmpty {
            bullets.append("Cable does not advertise an e-marker (basic cable)")
        }

        if port.opticalCable == true {
            bullets.append("Optical cable")
        }

        // Plug orientation
        if let orient = port.plugOrientation, orient != 0 {
            bullets.append("Plug inserted upside-down (handled automatically)")
        }

        // Headline + status
        if hasTB {
            self.status = .thunderboltCable
            self.headline = "Thunderbolt / USB4"
            self.subtitle = subtitleForCapabilities(usb3: true, dp: hasDP, emarker: hasEmarker)
        } else if hasUSB3 && hasDP {
            self.status = .displayCable
            self.headline = "USB-C with video"
            self.subtitle = "Carrying both data and DisplayPort video."
        } else if hasUSB3 {
            self.status = .dataDevice
            self.headline = "USB device"
            self.subtitle = "SuperSpeed data link is active."
        } else if hasUSB2 && active.contains("USB2") && !hasUSB3 {
            self.status = .dataDevice
            self.headline = "Slow USB device or charge-only cable"
            self.subtitle = "Only USB 2.0 is active. If you expected high speed, the cable may not support it."
        } else if active.isEmpty && supported.contains("USB2") {
            self.status = .charging
            self.headline = "Charging only"
            self.subtitle = "Power is flowing but no data link is established."
        } else {
            self.status = .unknown
            self.headline = "Connected"
            self.subtitle = "Couldn't determine cable type from this port."
        }

        self.bullets = bullets
    }
}

private func subtitleForCapabilities(usb3: Bool, dp: Bool, emarker: Bool) -> String {
    var parts: [String] = []
    if usb3 { parts.append("high-speed data") }
    if dp { parts.append("video") }
    if emarker { parts.append("smart cable") }
    if parts.isEmpty { return "Connected." }
    return "Supports " + parts.joined(separator: ", ") + "."
}
