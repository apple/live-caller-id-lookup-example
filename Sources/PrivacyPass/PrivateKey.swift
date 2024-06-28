// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import _CryptoExtras
import Crypto
import Foundation

public struct PrivateKey: Sendable {
    let backing: BackingPrivateKey

    public var publicKey: PublicKey {
        PublicKey(publicKey: backing.publicKey)
    }

    public var pemRepresentation: String {
        backing.pemRepresentation
    }

    public var derRepresentation: Data {
        backing.derRepresentation
    }

    public init() throws {
        self.backing = try .init(
            keySize: .init(bitCount: TokenTypeBlindRSAKeySizeInBits),
            parameters: TokenTypeBlindRSAParams)
    }

    public init(derRepresenation der: some DataProtocol) throws {
        self.backing = try BackingPrivateKey(derRepresentation: der, parameters: TokenTypeBlindRSAParams)
    }

    public init(pemRepresentation pem: String) throws {
        self.backing = try .init(pemRepresentation: pem, parameters: TokenTypeBlindRSAParams)
    }
}
