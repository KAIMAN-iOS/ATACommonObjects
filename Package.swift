// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ATACommonObjects",
    defaultLocalization: "en",
    platforms: [.iOS("13.0")],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ATACommonObjects",
            targets: ["ATACommonObjects"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/KAIMAN-iOS/KExtensions", .branch("master")),
        .package(url: "https://github.com/KAIMAN-iOS/ATAConfiguration", .branch("master")),
        .package(url: "https://github.com/ethanhuang13/NSAttributedStringBuilder", from: "0.3.0"),
        .package(url: "https://github.com/KAIMAN-iOS/KStorage", .branch("master")),
        .package(url: "https://github.com/malcommac/SwiftLocation", from: "5.1.0"),
        .package(url: "https://github.com/KAIMAN-iOS/PhoneNumberKit", .branch("master")),
        .package(url: "https://github.com/sindresorhus/Defaults", from: "6.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ATACommonObjects",
            dependencies: ["KExtensions", "ATAConfiguration", "SwiftLocation", "PhoneNumberKit", "KStorage", "NSAttributedStringBuilder", "Defaults"],
            resources: [.process("Villes/CP-FR.txt")])
    ]
)
