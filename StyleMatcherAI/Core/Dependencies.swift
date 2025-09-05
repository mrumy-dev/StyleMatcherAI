//
//  Dependencies.swift
//  StyleMatcherAI
//
//  This file documents all third-party dependencies used in the StyleMatcherAI project.
//

import Foundation

/**
 * StyleMatcherAI Dependencies Documentation
 *
 * This file serves as a centralized documentation for all third-party dependencies
 * used in the StyleMatcherAI project. It includes version information and usage purpose.
 */

// MARK: - Dependencies Overview

enum Dependencies {
    
    // MARK: - Networking
    static let alamofire = DependencyInfo(
        name: "Alamofire",
        version: "5.8.0+",
        repository: "https://github.com/Alamofire/Alamofire.git",
        purpose: "HTTP networking library for making API requests"
    )
    
    // MARK: - Image Loading and Caching
    static let sdWebImageSwiftUI = DependencyInfo(
        name: "SDWebImageSwiftUI",
        version: "2.2.0+",
        repository: "https://github.com/SDWebImage/SDWebImageSwiftUI.git",
        purpose: "SwiftUI integration for SDWebImage - async image loading"
    )
    
    static let kingfisher = DependencyInfo(
        name: "Kingfisher",
        version: "7.10.0+",
        repository: "https://github.com/onevcat/Kingfisher.git",
        purpose: "Advanced image downloading and caching library for iOS"
    )
    
    // MARK: - Machine Learning and AI
    static let swiftArgumentParser = DependencyInfo(
        name: "ArgumentParser",
        version: "1.2.0+",
        repository: "https://github.com/apple/swift-argument-parser.git",
        purpose: "Command line argument parsing for Swift applications"
    )
    
    // MARK: - Database and Storage
    static let sqliteSwift = DependencyInfo(
        name: "SQLite.swift",
        version: "0.14.0+",
        repository: "https://github.com/stephencelis/SQLite.swift.git",
        purpose: "Type-safe SQLite interface for Swift"
    )
    
    // MARK: - Backend as a Service
    static let supabase = DependencyInfo(
        name: "Supabase",
        version: "2.5.0+",
        repository: "https://github.com/supabase-community/supabase-swift.git",
        purpose: "Open source Firebase alternative - backend as a service platform"
    )
    
    // MARK: - Authentication & Firebase Services
    static let firebaseAuth = DependencyInfo(
        name: "FirebaseAuth",
        version: "10.15.0+",
        repository: "https://github.com/firebase/firebase-ios-sdk.git",
        purpose: "Firebase Authentication services"
    )
    
    static let firebaseFirestore = DependencyInfo(
        name: "FirebaseFirestore",
        version: "10.15.0+",
        repository: "https://github.com/firebase/firebase-ios-sdk.git",
        purpose: "Firebase Cloud Firestore NoSQL database"
    )
    
    static let firebaseStorage = DependencyInfo(
        name: "FirebaseStorage",
        version: "10.15.0+",
        repository: "https://github.com/firebase/firebase-ios-sdk.git",
        purpose: "Firebase Cloud Storage for file storage"
    )
    
    static let firebaseAnalytics = DependencyInfo(
        name: "FirebaseAnalytics",
        version: "10.15.0+",
        repository: "https://github.com/firebase/firebase-ios-sdk.git",
        purpose: "Firebase Analytics for app usage tracking"
    )
    
    // MARK: - In-App Purchases and Subscriptions
    static let revenueCat = DependencyInfo(
        name: "RevenueCat",
        version: "4.35.0+",
        repository: "https://github.com/RevenueCat/purchases-ios.git",
        purpose: "In-app purchase and subscription management platform"
    )
    
    // MARK: - UI Components and Utilities
    static let swiftUIIntrospect = DependencyInfo(
        name: "SwiftUIIntrospect",
        version: "0.12.0+",
        repository: "https://github.com/siteline/SwiftUI-Introspect.git",
        purpose: "SwiftUI introspection for accessing UIKit components"
    )
    
    // MARK: - Analytics and Crash Reporting
    static let mixpanel = DependencyInfo(
        name: "Mixpanel",
        version: "4.2.0+",
        repository: "https://github.com/mixpanel/mixpanel-swift.git",
        purpose: "Product analytics and user behavior tracking"
    )
    
    // MARK: - JSON Parsing
    static let anyCodable = DependencyInfo(
        name: "AnyCodable",
        version: "0.6.0+",
        repository: "https://github.com/Flight-School/AnyCodable.git",
        purpose: "Type-erased wrappers for Encodable and Decodable"
    )
    
    // MARK: - Security
    static let keychainSwift = DependencyInfo(
        name: "KeychainSwift",
        version: "20.0.0+",
        repository: "https://github.com/evgenyneu/keychain-swift.git",
        purpose: "Helper functions for storing and retrieving passwords in iOS Keychain"
    )
    
    // MARK: - Image Processing
    static let gifu = DependencyInfo(
        name: "Gifu",
        version: "3.3.0+",
        repository: "https://github.com/kaishin/Gifu.git",
        purpose: "High-performance animated GIF support for iOS"
    )
}

// MARK: - Dependency Info Structure

struct DependencyInfo {
    let name: String
    let version: String
    let repository: String
    let purpose: String
    
    var description: String {
        return """
        \(name) (\(version))
        Repository: \(repository)
        Purpose: \(purpose)
        """
    }
}

// MARK: - Dependency Management Extensions

extension Dependencies {
    
    /// All dependencies used in the project
    static var allDependencies: [DependencyInfo] {
        return [
            alamofire,
            sdWebImageSwiftUI,
            kingfisher,
            swiftArgumentParser,
            sqliteSwift,
            supabase,
            firebaseAuth,
            firebaseFirestore,
            firebaseStorage,
            firebaseAnalytics,
            revenueCat,
            swiftUIIntrospect,
            mixpanel,
            anyCodable,
            keychainSwift,
            gifu
        ]
    }
    
    /// Print all dependencies information
    static func printAllDependencies() {
        print("=== StyleMatcherAI Dependencies ===")
        print("Total dependencies: \(allDependencies.count)\n")
        
        for dependency in allDependencies {
            print(dependency.description)
            print("---")
        }
    }
    
    /// Get dependencies by category
    static func getDependenciesByCategory() -> [String: [DependencyInfo]] {
        return [
            "Networking": [alamofire],
            "Image Loading & Caching": [sdWebImageSwiftUI, kingfisher],
            "Machine Learning & AI": [swiftArgumentParser],
            "Database & Storage": [sqliteSwift],
            "Backend as a Service": [supabase],
            "Firebase Services": [firebaseAuth, firebaseFirestore, firebaseStorage, firebaseAnalytics],
            "In-App Purchases": [revenueCat],
            "UI Components": [swiftUIIntrospect],
            "Analytics": [mixpanel],
            "JSON Processing": [anyCodable],
            "Security": [keychainSwift],
            "Image Processing": [gifu]
        ]
    }
}