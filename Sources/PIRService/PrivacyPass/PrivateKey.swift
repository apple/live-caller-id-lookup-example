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

extension PrivacyPass {
    struct PrivateKey {
        let backing: _RSA.BlindSigning.PrivateKey

        init() throws {
            self.backing = try .init(keySize: .init(bitCount: TokenTypeBlindRSAKeySizeInBits))
        }

        init(privateKey: _RSA.BlindSigning.PrivateKey) {
            self.backing = privateKey
        }

        var publicKey: PublicKey {
            PublicKey(publicKey: backing.publicKey)
        }
    }
}
