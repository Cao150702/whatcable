// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhatCable",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "WhatCableCore",
            path: "Sources/WhatCableCore"
        ),
        .executableTarget(
            name: "WhatCable",
            dependencies: ["WhatCableCore"],
            path: "Sources/WhatCable"
        ),
        .executableTarget(
            name: "whatcable-cli",
            dependencies: ["WhatCableCore"],
            path: "Sources/WhatCableCLI"
        ),
        .testTarget(
            name: "WhatCableTests",
            dependencies: ["WhatCable", "WhatCableCore"],
            path: "Tests/WhatCableTests"
        )
    ]
)
