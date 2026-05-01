import Foundation

enum AppInfo {
    static let name = "WhatCable"
    static let version = "0.2.0"
    static let credit = "Bitmoor Ltd"
    static let tagline = "What can this USB-C cable actually do?"
    static let copyright = "© \(Calendar.current.component(.year, from: Date())) \(credit)"
}
