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
