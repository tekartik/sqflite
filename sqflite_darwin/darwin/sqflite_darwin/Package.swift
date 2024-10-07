// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sqflite_darwin",
    platforms: [
        .iOS("12.0"),
        .macOS("10.14")
    ],
    products: [
        // TODO: Update your library and target names.
        // If the plugin name contains "_", replace with "-" for the library name
        .library(name: "sqflite-darwin", targets: ["sqflite_darwin"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "sqflite_darwin",
            dependencies: [],
            resources: [
                .process("Resources"),

                // TODO: If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ],
            cSettings: [
                .headerSearchPath("include/sqflite_darwin")
            ]
        )
    ]
)