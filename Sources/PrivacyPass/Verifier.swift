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

public struct Verifier: Sendable {
    public let publicKey: PublicKey

    public init(publicKey: PublicKey) {
        self.publicKey = publicKey
    }

    public func verify(token: Token) throws -> Bool {
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
