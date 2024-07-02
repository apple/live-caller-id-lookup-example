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

public extension PublicKey {
    /// Prepare a token request.
    /// - Parameter challenge: Token challenge.
    /// - Returns: Returns a ``PreparedRequest`` that can be converted to a token request and after obtaining a token
    /// response can be converted to a token.
    /// - seealso: [RFC 9578: Client-to-Issuer
    /// Request](https://www.rfc-editor.org/rfc/rfc9578#name-client-to-issuer-request-2)
    func request(challenge: [UInt8]) throws
        -> PrivacyPass.PreparedRequest
    {
        /*
         nonce = random(32)
         challenge_digest = SHA256(challenge)
         token_input = concat(0x0002, // Token type field is 2 bytes long
         nonce,
         challenge_digest,
         token_key_id)
         blinded_msg, blind_inv = Blind(pkI, PrepareIdentity(token_input))
         */

        var nonce: [UInt8] = .init(repeating: 0, count: 32)
        var rng = SystemRandomNumberGenerator()
        nonce.withUnsafeMutableBytes { nonceBuffer in
            rng.fill(nonceBuffer)
        }
        let challengeDigest = Array(SHA256.hash(data: challenge))

        var tokenInput: [UInt8] = []
        tokenInput.append(contentsOf: PrivacyPass.TokenTypeBlindRSA.bigEndianBytes)
        tokenInput.append(contentsOf: nonce)
        tokenInput.append(contentsOf: challengeDigest)
        tokenInput.append(contentsOf: tokenKeyId)
        let blindingResult = try backing.blind(backing.prepare(tokenInput))

        return PreparedRequest(
            publicKey: self,
            nonce: nonce,
            challengeDigest: challengeDigest,
            blindingResult: blindingResult)
    }
}

/// Prepared token request.
///
/// This can be obtained from ``PublicKey/request(challenge:)``. This will contain the ``TokenRequest`` object and after
/// obtaining a ``TokenResponse`` can be finalized into a ``Token``.
public struct PreparedRequest {
    let publicKey: PublicKey
    let nonce: [UInt8]
    let challengeDigest: [UInt8]
    let blindingResult: _RSA.BlindSigning.BlindingResult

    /// Token request.
    ///
    /// This can be sent over to the token issuer to obtain a token response.
    public var tokenRequest: TokenRequest {
        TokenRequest(
            tokenType: TokenTypeBlindRSA,
            truncatedTokenKeyId: publicKey.truncatedTokenKeyId,
            blindedMsg: Array(blindingResult.blindedMessage))
    }

    /// Finalize the token issuance.
    ///
    /// - warning: After calling ``finalize(response:)`` and obtaining a token, the ``PreparedRequest`` should be
    /// discraded and not reused for obtaining more tokens.
    /// - Parameter response: Token response from the token issuer,
    /// - Returns: Issued Privacy Pass Token.
    /// - seealso: [RFC 9578: Finalization](https://www.rfc-editor.org/rfc/rfc9578#name-finalization-2)
    public func finalize(response: TokenResponse) throws -> Token {
        // recompute tokenInput
        var tokenInput: [UInt8] = []
        tokenInput.append(contentsOf: PrivacyPass.TokenTypeBlindRSA.bigEndianBytes)
        tokenInput.append(contentsOf: nonce)
        tokenInput.append(contentsOf: challengeDigest)
        tokenInput.append(contentsOf: publicKey.tokenKeyId)

        let signature = _RSA.BlindSigning.BlindSignature(rawRepresentation: response.blindSignature)
        /*
         authenticator =
           Finalize(pkI, PrepareIdentity(token_input), blind_sig, blind_inv)
         */
        let authenticator = try publicKey.backing.finalize(
            signature,
            for: publicKey.backing.prepare(tokenInput),
            blindingInverse: blindingResult.inverse)

        return Token(
            tokenType: TokenTypeBlindRSA,
            nonce: nonce,
            challengeDigest: challengeDigest,
            tokenKeyId: publicKey.tokenKeyId,
            authenticator: Array(authenticator.rawRepresentation))
    }
}
