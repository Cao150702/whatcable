import Foundation

public enum AppInfo {
    public static let name = "WhatCable"
    public static let version: String = {
        // Single source of truth lives in the .app's Info.plist (written by
        // scripts/build-app.sh). Falls back to "dev" when run via `swift run`,
        // which has no bundled Info.plist.
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "dev"
    }()
    public static let credit = "Darryl Morley"
    public static let tagline = "What can this USB-C cable actually do?"
    public static let copyright = "© \(Calendar.current.component(.year, from: Date())) \(credit)"
    public static let helpURL = URL(string: "https://github.com/darrylmorley/whatcable")!

    /// Compare dot-separated numeric versions. Non-numeric segments compare as 0.
    public static func isNewer(remote: String, current: String) -> Bool {
        let r = parts(remote)
        let c = parts(current)
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv != cv { return rv > cv }
        }
        return false
    }

    private static func parts(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }
}
