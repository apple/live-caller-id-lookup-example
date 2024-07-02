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

/// Private key.
public struct PrivateKey: Sendable {
    let backing: BackingPrivateKey

    /// Public key that corresponds to this private key.
    public var publicKey: PublicKey {
        PublicKey(publicKey: backing.publicKey)
    }

    /// PEM representation of the private key.
    public var pemRepresentation: String {
        backing.pemRepresentation
    }

    /// DER representation of the private key.
    public var derRepresentation: Data {
        backing.derRepresentation
    }

    /// Generate a new private key.
    public init() throws {
        self.backing = try .init(
            keySize: .init(bitCount: TokenTypeBlindRSAKeySizeInBits),
            parameters: TokenTypeBlindRSAParams)
    }

    /// Load a private key from DER representation.
    /// - Parameter der: DER encoded private key.
    public init(derRepresenation der: some DataProtocol) throws {
        self.backing = try BackingPrivateKey(derRepresentation: der, parameters: TokenTypeBlindRSAParams)
    }

    /// Load a private key from PEM representation.
    /// - Parameter pem: PEM encoded private key.
    public init(pemRepresentation pem: String) throws {
        self.backing = try .init(pemRepresentation: pem, parameters: TokenTypeBlindRSAParams)
    }
}
