// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "CoreAnimationPrivate",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CoreAnimationPrivate",
            targets: ["CoreAnimationPrivate"]
        )
    ],
    targets: [
        // Vends the private QuartzCore/Core Animation headers as a Clang module.
        // These headers only *declare* the interfaces; the symbols are resolved at
        // runtime/link time from the system QuartzCore framework.
        .target(
            name: "CoreAnimationPrivateObjC",
            linkerSettings: [
                .linkedFramework("QuartzCore"),
                .linkedFramework("IOSurface")
            ]
        ),
        // Ergonomic Swift wrappers over the raw private interfaces.
        .target(
            name: "CoreAnimationPrivate",
            dependencies: ["CoreAnimationPrivateObjC"],
            linkerSettings: [
                .linkedFramework("QuartzCore"),
                .linkedFramework("IOSurface"),
                .linkedFramework("AppKit")
            ]
        ),
        .testTarget(
            name: "CoreAnimationPrivateTests",
            dependencies: ["CoreAnimationPrivate"]
        )
    ]
)

// Core Animation is inherently main-thread, so default these Swift targets to
// MainActor isolation and opt into the relevant upcoming concurrency features.
// The Clang (Objective-C) target takes no Swift settings.
for target in package.targets where target.name != "CoreAnimationPrivateObjC" {
    var settings = target.swiftSettings ?? []
    settings.append(contentsOf: [
        .defaultIsolation(MainActor.self),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault")
    ])
    if !target.isTest {
        settings.append(.enableUpcomingFeature("InferIsolatedConformances"))
    }
    target.swiftSettings = settings
}
