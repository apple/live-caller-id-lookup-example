// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

extension PrivacyPass {
    /*
     struct {
     uint8_t blind_sig[Nk];
     } TokenResponse;
     */
    struct TokenResponse: Equatable {
        static let sizeInBytes = TokenTypeBlindRSANK

        let blindSignature: [UInt8]

        init(blindSignature: [UInt8]) {
            self.blindSignature = blindSignature
        }

        init(from bytes: some Collection<UInt8>) throws {
            guard bytes.count == Self.sizeInBytes else {
                throw PrivacyPassError.invalidTokenResponseSize
            }
            self.blindSignature = Array(bytes)
        }

        func bytes() -> [UInt8] {
            blindSignature
        }
    }
}
