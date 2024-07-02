// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import PrivacyPass
import XCTest

class PrivacyPassPublicTests: XCTestCase {
    func testIssuance() throws {
        let privateKey = try PrivacyPass.PrivateKey()
        let publicKey = privateKey.publicKey
        let preparedRequest = try publicKey.request(challenge: [1, 2, 3])
        let issuer = try PrivacyPass.Issuer(privateKey: privateKey)
        let response = try issuer.issue(request: preparedRequest.tokenRequest)
        let token = try preparedRequest.finalize(response: response)
        let verifier = PrivacyPass.Verifier(publicKey: publicKey)
        XCTAssert(try verifier.verify(token: token))
    }
}
