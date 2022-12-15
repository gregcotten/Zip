// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Zip",
    products: [
        .library(name: "Zip", targets: ["Zip"])
    ],
    targets: [
        .target(
            name: "zlib",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-Wno-shorten-64-to-32"]),
                .define("Z_HAVE_UNISTD_H", .when(platforms: [.macOS, .linux])),
                .define("HAVE_STDARG_H"),
                .define("HAVE_HIDDEN"),
                .define("_CRT_SECURE_NO_DEPRECATE", .when(platforms: [.windows])),
                .define("_CRT_NONSTDC_NO_DEPRECATE", .when(platforms: [.windows])),
            ]),
        .target(
            name: "Minizip",
            dependencies: ["zlib"]),
        .target(
            name: "Zip",
            dependencies: ["Minizip"]),
        .testTarget(
            name: "ZipTests",
            dependencies: ["Zip"],
            resources: [
                .process("Resources"),
            ]),
    ]
)
