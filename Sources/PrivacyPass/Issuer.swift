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

/// Token Issuer.
public struct Issuer: Sendable {
    /// Private key.
    public let privateKey: PrivateKey
    /// Truncated token key ID.
    public let truncatedTokenKeyId: UInt8

    /// Public key.
    public var publicKey: PublicKey {
        privateKey.publicKey
    }

    /// Initialize a token issuer.
    /// - Parameter privateKey: Private key to use for issuing tokens.
    public init(privateKey: PrivateKey) throws {
        guard privateKey.backing.keySizeInBits == TokenTypeBlindRSAKeySizeInBits else {
            throw PrivacyPassError.invalidKeySize
        }
        self.privateKey = privateKey
        self.truncatedTokenKeyId = privateKey.publicKey.truncatedTokenKeyId
    }

    /// Issue a token response.
    ///
    /// Checks that request has:
    /// - correct token type,
    /// - correct truncated token key identitifer,
    /// - correct blindend message length.
    /// - Parameter request: The token request.
    /// - Returns: Token response.
    /// - Throws: If any of the checks on the token request fail an error will be thrown.
    /// - seealso: [RFC 9578: Issuer-to-Client
    /// Response](https://www.rfc-editor.org/rfc/rfc9578#name-issuer-to-client-response-2)
    public func issue(request: TokenRequest) throws -> TokenResponse {
        guard request.tokenType == TokenTypeBlindRSA else {
            throw PrivacyPassError.invalidTokenType
        }
        guard request.truncatedTokenKeyId == truncatedTokenKeyId else {
            throw PrivacyPassError.invalidTokenKeyId
        }
        guard request.blindedMsg.count == TokenTypeBlindRSANK else {
            throw PrivacyPassError.invalidTokenRequestBlindedMessageSize
        }

        let signature = try privateKey.backing.blindSignature(for: request.blindedMsg)
        let blindSignature = signature.withUnsafeBytes { signatureBuffer in
            Array(signatureBuffer)
        }
        return TokenResponse(blindSignature: blindSignature)
    }
}
