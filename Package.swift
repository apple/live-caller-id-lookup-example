// swift-tools-version: 6.0
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
            revision: "508f0fe02676986e59c64ce1a2624107ff54f870"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-asn1.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.5.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird", exact: "2.0.0-rc.2"),
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
            ],
            exclude: ["protobuf"]),
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
