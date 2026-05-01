import Foundation
import WhatCableCore

@main
struct WhatCableCLI {
    @MainActor
    static func main() {
        // Hand-rolled flag parsing. We only have a handful of flags; pulling
        // in swift-argument-parser would be heavier than the rest of the CLI.
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("-h") || args.contains("--help") {
            print(helpText)
            return
        }
        if args.contains("--version") {
            print(AppInfo.version)
            return
        }

        let showRaw = args.contains("--raw")

        // Reject unknown flags so typos don't silently produce default output.
        let knownFlags: Set<String> = ["--raw", "-h", "--help", "--version"]
        for arg in args where arg.hasPrefix("-") && !knownFlags.contains(arg) {
            FileHandle.standardError.write(Data("whatcable: unknown option \(arg)\n".utf8))
            FileHandle.standardError.write(Data(helpText.utf8))
            exit(2)
        }

        let portWatcher = USBCPortWatcher()
        let powerWatcher = PowerSourceWatcher()
        let pdWatcher = PDIdentityWatcher()

        portWatcher.refresh()
        powerWatcher.refresh()
        pdWatcher.refresh()

        let output = TextFormatter.render(
            ports: portWatcher.ports,
            sources: powerWatcher.sources,
            identities: pdWatcher.identities,
            showRaw: showRaw
        )
        print(output, terminator: "")
    }

    static let helpText = """
    whatcable \(AppInfo.version) — \(AppInfo.tagline)

    Usage: whatcable [options]

    Options:
      --raw          Include raw IOKit properties for each port
      --version      Print version and exit
      -h, --help     Show this help and exit

    """
}
