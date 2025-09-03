// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StyleMatcherAI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "StyleMatcherAI",
            targets: ["StyleMatcherAI"]),
    ],
    dependencies: [
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // Image Loading and Caching
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.0"),
        
        // Machine Learning and AI
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        
        // Database and Storage
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0"),
        
        // Authentication
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.15.0"),
        
        // UI Components and Utilities
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.12.0"),
        
        // Analytics and Crash Reporting
        .package(url: "https://github.com/mixpanel/mixpanel-swift.git", from: "4.2.0"),
        
        // JSON Parsing
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),
        
        // Keychain Services
        .package(url: "https://github.com/evgenyneu/keychain-swift.git", from: "20.0.0"),
        
        // Image Processing
        .package(url: "https://github.com/kaishin/Gifu.git", from: "3.3.0"),
    ],
    targets: [
        .target(
            name: "StyleMatcherAI",
            dependencies: [
                "Alamofire",
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
                "AnyCodable",
                .product(name: "KeychainSwift", package: "keychain-swift"),
                "Gifu"
            ]
        ),
        .testTarget(
            name: "StyleMatcherAITests",
            dependencies: ["StyleMatcherAI"]
        ),
    ]
)