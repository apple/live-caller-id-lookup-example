// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
]

let package = Package(
    name: "pir-service",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PIRService", targets: ["PIRService"]),
        .executable(name: "ConstructDatabase", targets: ["ConstructDatabase"]),
        .library(name: "PrivacyPass", targets: ["PrivacyPass"]),
    ],
    dependencies: [
        // TODO: need to switch to a repository URL & a version number
        .package(
            url: "git@github.pie.apple.com:SIMLCryptoAndPrivacy/swift-he.git",
            revision: "a59c7d32316e4d60306ddd7edf615aa6e6c075a6"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-asn1.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.5.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", exact: "2.0.0-beta.8"),
    ],
    targets: [
        .executableTarget(
            name: "PIRService",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
                // TODO: need to replace "swift-he" with "swift-homomorphic-encryption"
                // when moving to proper package url
                .product(name: "HomomorphicEncryptionProtobuf", package: "swift-he"),
                .product(name: "PrivateInformationRetrievalProtobuf", package: "swift-he"),
                "PrivacyPass",
            ],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "PIRServiceTests",
            dependencies: [
                .byName(name: "PIRService"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .product(name: "TestUtil", package: "swift-he"),
            ],
            swiftSettings: swiftSettings),
        .executableTarget(
            name: "ConstructDatabase",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                // TODO: need to replace "swift-he" with "swift-homomorphic-encryption"
                // when moving to proper package url
                .product(name: "PrivateInformationRetrievalProtobuf", package: "swift-he"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]),
        .target(
            name: "PrivacyPass",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ]),
        .testTarget(
            name: "PrivacyPassTests",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
                .byName(name: "PrivacyPass"),
            ],
            exclude: ["TestVectors/PrivacyPassPublicTokens.json"]),
    ])
