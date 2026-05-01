import Foundation
import WhatCableCore

enum TextFormatter {
    static func render(
        ports: [USBCPort],
        sources: [PowerSource],
        identities: [PDIdentity],
        showRaw: Bool
    ) -> String {
        if ports.isEmpty {
            return "No USB-C / MagSafe ports were found on this Mac.\n"
        }

        var out = ""
        for (i, port) in ports.enumerated() {
            if i > 0 { out += "\n" }
            out += renderPort(
                port,
                sources: filterSources(port, all: sources),
                identities: filterIdentities(port, all: identities),
                showRaw: showRaw
            )
        }
        return out
    }

    private static func renderPort(
        _ port: USBCPort,
        sources: [PowerSource],
        identities: [PDIdentity],
        showRaw: Bool
    ) -> String {
        let summary = PortSummary(port: port, sources: sources, identities: identities)
        let label = port.portDescription ?? port.serviceName
        let typeSuffix = port.portTypeDescription.map { " (\($0))" } ?? ""

        var out = "=== \(label)\(typeSuffix) ===\n"
        out += "\(summary.headline)\n"
        out += "\(summary.subtitle)\n"
        if !summary.bullets.isEmpty {
            out += "\n"
            for bullet in summary.bullets {
                out += "  • \(bullet)\n"
            }
        }

        if let diag = ChargingDiagnostic(port: port, sources: sources, identities: identities) {
            out += "\nCharging: \(diag.summary)\n"
            out += "  \(diag.detail)\n"
        }

        if showRaw {
            out += "\nRaw IOKit properties:\n"
            for key in port.rawProperties.keys.sorted() {
                let value = port.rawProperties[key] ?? ""
                out += "  \(key) = \(value)\n"
            }
        }

        return out
    }

    private static func filterSources(_ port: USBCPort, all: [PowerSource]) -> [PowerSource] {
        guard let key = port.portKey else { return [] }
        return all.filter { $0.portKey == key }
    }

    private static func filterIdentities(_ port: USBCPort, all: [PDIdentity]) -> [PDIdentity] {
        guard let key = port.portKey else { return [] }
        return all.filter { $0.portKey == key }
    }
}
