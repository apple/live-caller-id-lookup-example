// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import Foundation
import PrivacyPass

protocol UserTokenAuthenticator: Sendable {
    func authenticate(userToken: String) async throws -> UserTier?
}

actor PrivacyPassState<UserAuthenticator: UserTokenAuthenticator> {
    struct TieredVerifier {
        let verifier: PrivacyPass.Verifier
        let tier: UserTier
    }

    let issuerRequestUri: URL
    let userAuthenticator: UserAuthenticator
    // map from tier to issuer
    var issuers: [UserTier: PrivacyPass.Issuer]
    // map from truncate key id to verifier & tier
    var verifiers: [UInt8: TieredVerifier]

    init(issuerRequestUri: URL, userAuthenticator: UserAuthenticator) throws {
        var issuers: [UserTier: PrivacyPass.Issuer] = [:]
        var verifiers: [UInt8: TieredVerifier] = [:]
        // generate issuers for each user tier and avoid truncated key id collisions
        for tier in UserTier.allCases {
            var issuer: PrivacyPass.Issuer
            repeat {
                issuer = try PrivacyPass.Issuer(privateKey: .init())
            } while verifiers[issuer.truncatedTokenKeyId] != nil
            issuers[tier] = issuer
            verifiers[issuer.truncatedTokenKeyId] = TieredVerifier(
                verifier: PrivacyPass.Verifier(publicKey: issuer.publicKey),
                tier: tier)
        }

        self.issuerRequestUri = issuerRequestUri
        self.userAuthenticator = userAuthenticator
        self.issuers = issuers
        self.verifiers = verifiers
    }
}
