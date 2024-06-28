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

extension PublicKey {
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
        let tokenKeyId = try tokenKeyID()

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

struct PreparedRequest {
    let publicKey: PublicKey
    let nonce: [UInt8]
    let challengeDigest: [UInt8]
    let blindingResult: _RSA.BlindSigning.BlindingResult

    func tokenRequest() throws -> TokenRequest {
        try TokenRequest(
            tokenType: TokenTypeBlindRSA,
            truncatedTokenKeyId: publicKey.truncatedTokenKeyID(),
            blindedMsg: Array(blindingResult.blindedMessage))
    }

    func finalize(response: TokenResponse) throws -> Token {
        let tokenKeyId = try publicKey.tokenKeyID()

        // recompute tokenInput
        var tokenInput: [UInt8] = []
        tokenInput.append(contentsOf: PrivacyPass.TokenTypeBlindRSA.bigEndianBytes)
        tokenInput.append(contentsOf: nonce)
        tokenInput.append(contentsOf: challengeDigest)
        tokenInput.append(contentsOf: tokenKeyId)

        let signature = _RSA.BlindSigning.BlindSignature(rawRepresentation: response.blindSignature)
        /*
         authenticator =
           Finalize(pkI, PrepareIdentity(token_input), blind_sig, blind_inv)
         */
        let authenticator = try publicKey.backing.finalize(
            signature,
            for: publicKey.backing.prepare(tokenInput),
            blindingInverse: blindingResult.inverse)

        return try Token(
            tokenType: TokenTypeBlindRSA,
            nonce: nonce,
            challengeDigest: challengeDigest,
            tokenKeyId: publicKey.tokenKeyID(),
            authenticator: Array(authenticator.rawRepresentation))
    }
}
