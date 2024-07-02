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
import Foundation

/// Token verifier.
public struct Verifier: Sendable {
    /// Public key used to verify tokens.
    public let publicKey: PublicKey

    /// Challenge digest to use for verification.
    public let challengeDigest: [UInt8]?

    /// Initialize a verifier.
    /// - Parameter publicKey: Public key to use for verification.
    /// - Parameter challengeDigest: Optional challenge digest.
    public init(publicKey: PublicKey, challengeDigest: [UInt8]? = nil) {
        self.publicKey = publicKey
        self.challengeDigest = challengeDigest
    }

    /// Verify that the token is valid.
    ///
    /// This function verifies that the given token has:
    ///  - correct token type,
    ///  - correct challenge digest (if present in the verifier),
    ///  - valid signature.
    /// - Parameter token: The token whose validity is being verified.
    /// - Returns: If the token is valid.
    /// - seealso: [RFC 9578: Token Verification](https://www.rfc-editor.org/rfc/rfc9578#name-token-verification-2)
    public func verify(token: Token) throws -> Bool {
        // fast return, when token type or token key id are invalid
        guard token.tokenType == TokenTypeBlindRSA,
              token.tokenKeyId == publicKey.tokenKeyId
        else {
            return false
        }

        // verify the challenege digest, if available
        if let challengeDigest {
            guard token.challengeDigest == challengeDigest else {
                return false
            }
        }
        /*
         token_authenticator_input =
           concat(Token.token_type,
                  Token.nonce,
                  Token.challenge_digest,
                  Token.token_key_id)
         valid = RSASSA-PSS-VERIFY(pkI,
                                   token_authenticator_input,
                                   Token.authenticator)
         */
        let tokenAuthenticatorInputSize = MemoryLayout.size(ofValue: token.tokenType) + MemoryLayout
            .size(ofValue: token.nonce) + MemoryLayout.size(ofValue: token.challengeDigest) + MemoryLayout
            .size(ofValue: token.tokenKeyId)
        var inputMessage = Data(capacity: tokenAuthenticatorInputSize)
        inputMessage.append(contentsOf: token.tokenType.bigEndianBytes)
        inputMessage.append(contentsOf: token.nonce)
        inputMessage.append(contentsOf: token.challengeDigest)
        inputMessage.append(contentsOf: token.tokenKeyId)
        let preparedMessage = publicKey.backing.prepare(inputMessage)
        let blindSignature = _RSA.Signing.RSASignature(rawRepresentation: token.authenticator)
        return publicKey.backing.isValidSignature(blindSignature, for: preparedMessage)
    }
}
