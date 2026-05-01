import Foundation
import Darwin

/// ANSI color helpers. Disabled automatically when stdout isn't a TTY
/// (piped output, redirected to file) or when NO_COLOR is set —
/// see https://no-color.org for the convention.
enum ANSI {
    static let isEnabled: Bool = {
        if ProcessInfo.processInfo.environment["NO_COLOR"] != nil { return false }
        return isatty(fileno(stdout)) != 0
    }()

    static let reset = "\u{1B}[0m"
    static let bold = "\u{1B}[1m"
    static let dim = "\u{1B}[2m"

    static let red = "\u{1B}[31m"
    static let green = "\u{1B}[32m"
    static let yellow = "\u{1B}[33m"
    static let blue = "\u{1B}[34m"
    static let magenta = "\u{1B}[35m"
    static let cyan = "\u{1B}[36m"
    static let gray = "\u{1B}[90m"

    static func wrap(_ codes: String, _ text: String) -> String {
        guard isEnabled else { return text }
        return codes + text + reset
    }
}
