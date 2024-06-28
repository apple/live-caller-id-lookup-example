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

public struct Issuer: Sendable {
    public let privateKey: PrivateKey
    public let truncatedTokenKeyId: UInt8

    public var publicKey: PublicKey {
        privateKey.publicKey
    }

    public init(privateKey: PrivateKey) throws {
        guard privateKey.backing.keySizeInBits == TokenTypeBlindRSAKeySizeInBits else {
            throw PrivacyPassError.invalidKeySize
        }
        self.privateKey = privateKey
        self.truncatedTokenKeyId = try privateKey.publicKey.truncatedTokenKeyID()
    }

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
