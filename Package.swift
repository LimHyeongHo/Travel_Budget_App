// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TravelBudgetCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TravelBudgetCore", targets: ["TravelBudgetCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "TravelBudgetCore",
            dependencies: [.product(name: "Collections", package: "swift-collections")]
        ),
        .testTarget(name: "TravelBudgetCoreTests", dependencies: ["TravelBudgetCore"]),
    ]
)
