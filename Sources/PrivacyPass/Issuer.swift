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
            throw PrivacyPassError(code: .invalidKeySize)
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
            throw PrivacyPassError(code: .invalidTokenType)
        }
        guard request.truncatedTokenKeyId == truncatedTokenKeyId else {
            throw PrivacyPassError(code: .invalidTokenKeyId)
        }
        guard request.blindedMsg.count == TokenTypeBlindRSANK else {
            throw PrivacyPassError(code: .invalidTokenRequestBlindedMessageSize)
        }

        let signature = try privateKey.backing.blindSignature(for: request.blindedMsg)
        let blindSignature = signature.withUnsafeBytes { signatureBuffer in
            Array(signatureBuffer)
        }
        return TokenResponse(blindSignature: blindSignature)
    }
}
