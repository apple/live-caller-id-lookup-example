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

/// Privacy Pass Token.
///
/// This is the token struct.
/// ```
/// struct {
///   uint16_t token_type = 0x0002; /* Type Blind RSA (2048-bit) */
///   uint8_t nonce[32];
///   uint8_t challenge_digest[32];
///   uint8_t token_key_id[32];
///   uint8_t authenticator[Nk];
/// } Token;
/// ```
public struct Token: Equatable, Sendable {
    static let nonceSize = 32
    static let challengeDigestSize = 32
    static let tokenKeyIdSize = 32
    static let authenticatorSize = TokenTypeBlindRSANK
    static let sizeInBytes = MemoryLayout<UInt16>
        .size + nonceSize + challengeDigestSize + tokenKeyIdSize + authenticatorSize

    /// Token type.
    public let tokenType: UInt16
    /// Unique nonce for the token.
    public let nonce: [UInt8]
    /// Challenge digest.
    public let challengeDigest: [UInt8]
    /// Token key identifier.
    public let tokenKeyId: [UInt8]
    /// Token authenticator.
    public let authenticator: [UInt8]

    /// Initialize a Token.
    ///
    /// - Warning: This initializer is probably unneeded. Please use ``PreparedRequest/finalize(response:)`` to obtain a
    /// token.
    /// - Parameters:
    ///   - tokenType: Token type.
    ///   - nonce: Nonce.
    ///   - challengeDigest: Challenge digest.
    ///   - tokenKeyId: Token key identitifer.
    ///   - authenticator: Authenticator.
    public init(
        tokenType: UInt16,
        nonce: [UInt8],
        challengeDigest: [UInt8],
        tokenKeyId: [UInt8],
        authenticator: [UInt8])
    {
        self.tokenType = tokenType
        self.nonce = nonce
        self.challengeDigest = challengeDigest
        self.tokenKeyId = tokenKeyId
        self.authenticator = authenticator
    }

    /// Load a Private Pass Token from bytes.
    /// - Parameter bytes: Collection of bytes representing a token.
    public init<C: Collection<UInt8>>(from bytes: C) throws {
        guard bytes.count == Self.sizeInBytes else {
            throw PrivacyPassError(code: .invalidTokenSize)
        }
        var offset = bytes.startIndex

        func extractBytes(count: Int) -> C.SubSequence {
            let end = bytes.index(offset, offsetBy: count)
            defer {
                offset = end
            }
            return bytes[offset..<end]
        }

        self.tokenType = UInt16(bigEndianBytes: extractBytes(count: MemoryLayout<UInt16>.size))
        self.nonce = Array(extractBytes(count: Self.nonceSize))
        self.challengeDigest = Array(extractBytes(count: Self.challengeDigestSize))
        self.tokenKeyId = Array(extractBytes(count: Self.tokenKeyIdSize))
        self.authenticator = Array(extractBytes(count: Self.authenticatorSize))
    }

    /// Convert to byte array.
    /// - Returns: A binary representation of the token.
    public func bytes() -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(Self.sizeInBytes)
        bytes.append(contentsOf: tokenType.bigEndianBytes)
        bytes.append(contentsOf: nonce)
        bytes.append(contentsOf: challengeDigest)
        bytes.append(contentsOf: tokenKeyId)
        bytes.append(contentsOf: authenticator)
        return bytes
    }
}
