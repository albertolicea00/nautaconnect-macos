// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NautaConnect",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "NautaConnectCore"),
        .executableTarget(
            name: "NautaConnect",
            dependencies: ["NautaConnectCore"]
        ),
        .testTarget(
            name: "NautaConnectCoreTests",
            dependencies: ["NautaConnectCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
