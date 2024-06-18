// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

enum PrivacyPass {
    static let TokenTypeBlindRSA: UInt16 = 2
    static let TokenTypeBlindRSAKeySizeInBits: Int = 2048
    static let TokenTypeBlindRSANK: Int = 256
    static let TokenTypeBlindRSASaltLength: Int = 48
}
