// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Cocoon",
    platforms: [.macOS(.v10_15), .iOS(.v17)],
    products: [
        .library(
            name: "Cocoon",
            type: .dynamic,
            targets: ["Cocoon"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "RealmSwiftBinary",
            url: "https://github.com/realm/realm-swift/releases/download/v20.0.3/RealmSwift@16.4.spm.zip",
            checksum: "840a5fb0ad5d55d29de2ced5a3c9cb9114360ad906c30b0502ed2a33f1dbba8c"
        ),
        .binaryTarget(
            name: "RealmBinary",
            url: "https://github.com/realm/realm-swift/releases/download/v20.0.3/Realm.spm.zip",
            checksum: "6185f0f65c081da02ac90cd3e3db867dfa832cc2f8f7f4d7aba2f091994b311f"
        ),
        .target(
            name: "Cocoon",
            dependencies: [
                "CocoonMacro",
                "CocoonCore"
            ]
        ),
        .target(
            name: "CocoonMacro",
            dependencies: [
                "CocoonCore",
                "CocoonMacros"
            ]
        ),
        .target(
            name: "CocoonCore",
            dependencies: [
                "RealmSwiftBinary",
                "RealmBinary",
            ]
        ),
        .macro(
            name: "CocoonMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "CocoonMacroTests",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                "CocoonMacros"
            ]
        ),
        .testTarget(
            name: "CocoonTests",
            dependencies: ["Cocoon"]
        )
    ]
)
