// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("StrictConcurrency"),
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
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-asn1.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.5.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-homomorphic-encryption", exact: "1.0.0-alpha.2"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", exact: "2.0.0-rc.2"),
    ],
    targets: [
        .executableTarget(
            name: "PIRService",
            dependencies: [
                "PrivacyPass",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "HomomorphicEncryptionProtobuf", package: "swift-homomorphic-encryption"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "PrivateInformationRetrievalProtobuf", package: "swift-homomorphic-encryption"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "PIRServiceTests",
            dependencies: [
                "PIRService",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ],
            swiftSettings: swiftSettings),
        .executableTarget(
            name: "ConstructDatabase",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PrivateInformationRetrievalProtobuf", package: "swift-homomorphic-encryption"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            exclude: ["protobuf"],
            swiftSettings: swiftSettings),
        .target(
            name: "PrivacyPass",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
            ],
            swiftSettings: swiftSettings),
        .testTarget(
            name: "PrivacyPassTests",
            dependencies: [
                "PrivacyPass",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
            ],
            exclude: ["TestVectors/PrivacyPassPublicTokens.json"],
            swiftSettings: swiftSettings),
    ])
