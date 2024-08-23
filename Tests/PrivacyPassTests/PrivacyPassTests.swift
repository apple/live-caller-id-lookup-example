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
import Crypto
import Foundation
@testable import PrivacyPass
import XCTest

class PrivacyPassTests: XCTestCase {
    func testConvertAndLoadPublicKey() throws {
        let privateKey = try PrivacyPass.PrivateKey()
        let spki = try privateKey.publicKey.spki()
        _ = try PrivacyPass.PublicKey(fromSPKI: spki)
    }

    func testIssuance() async throws {
        let privateKey = try PrivacyPass.PrivateKey()
        let publicKey = privateKey.publicKey
        let preparedRequest = try publicKey.request(challenge: [1, 2, 3])
        let issuer = try PrivacyPass.Issuer(privateKey: privateKey)
        let response = try issuer.issue(request: preparedRequest.tokenRequest)
        let token = try preparedRequest.finalize(response: response)
        let verifier = PrivacyPass.Verifier(publicKey: publicKey, nonceStore: InMemoryNonceStore())
        let valid = try await verifier.verify(token: token)
        XCTAssert(valid)
    }

    func testNoDoubleSpend() async throws {
        let privateKey = try PrivacyPass.PrivateKey()
        let publicKey = privateKey.publicKey
        let preparedRequest = try publicKey.request(challenge: [1, 2, 3])
        let issuer = try PrivacyPass.Issuer(privateKey: privateKey)
        let response = try issuer.issue(request: preparedRequest.tokenRequest)
        let token = try preparedRequest.finalize(response: response)
        let verifier = PrivacyPass.Verifier(publicKey: publicKey, nonceStore: InMemoryNonceStore())
        let valid = try await verifier.verify(token: token)
        XCTAssert(valid)
        let notValid = try await verifier.verify(token: token)
        XCTAssertFalse(notValid)
    }

    func testVectors() async throws {
        struct TestVector: Codable {
            let skS: String
            let pkS: String
            let token_challenge: String
            let nonce: String
            let blind: String
            let salt: String
            let token_request: String
            let token_response: String
            let token: String

            static func load(from path: URL) throws -> [Self] {
                let json = try Data(contentsOf: path)
                let decoder = JSONDecoder()
                return try decoder.decode([Self].self, from: json)
            }
        }

        enum InvalidHexString: Error {
            case invalidHexString
        }

        func unhex(_ hexString: String) throws -> [UInt8] {
            guard let array = Array(hexEncoded: hexString) else {
                throw InvalidHexString.invalidHexString
            }
            return array
        }

        let testVectors = try TestVector.load(from: URL(
            fileURLWithPath: "TestVectors/PrivacyPassPublicTokens.json",
            relativeTo: URL(fileURLWithPath: #filePath)))
        for testVector in testVectors {
            // load private key
            let skS = try unhex(testVector.skS)
            let privateKeyPEM = try XCTUnwrap(String(decoding: Data(skS), as: UTF8.self))
            let privateKey = try PrivacyPass.PrivateKey(pemRepresentation: privateKeyPEM)
            // verify public key is correctly encoded
            let pkS = try unhex(testVector.pkS)
            let spki = try privateKey.publicKey.spki()
            XCTAssertEqual(spki, pkS)
            // verify we can load the public key directly from SPKI
            let publicKey = try PrivacyPass.PublicKey(fromSPKI: pkS)
            // construct token request
            let tokenChallenge = try unhex(testVector.token_challenge)
            // because we cannot feed in random bytes to blinding step, we will ignore the generated tokenRequest
            _ = try publicKey.request(challenge: tokenChallenge)
            // load token request
            let tokenRequestBytes = try unhex(testVector.token_request)
            let tokenRequest = try PrivacyPass.TokenRequest(from: tokenRequestBytes)
            XCTAssertEqual(tokenRequest.bytes(), tokenRequestBytes)
            // verify token response
            let tokenResponseBytes = try unhex(testVector.token_response)
            let tokenResponse = try PrivacyPass.TokenResponse(from: tokenResponseBytes)
            let issuer = try PrivacyPass.Issuer(privateKey: privateKey)
            let issuedResponse = try issuer.issue(request: tokenRequest)
            XCTAssertEqual(issuedResponse, tokenResponse)
            XCTAssertEqual(issuedResponse.bytes(), tokenResponseBytes)
            // load token
            let tokenBytes = try unhex(testVector.token)
            let token = try PrivacyPass.Token(from: tokenBytes)
            XCTAssertEqual(token.bytes(), tokenBytes)
            // verify token validity
            let verifier = PrivacyPass.Verifier(publicKey: privateKey.publicKey, nonceStore: InMemoryNonceStore())
            let verified = try await verifier.verify(token: token)
            XCTAssertTrue(verified)
        }
    }
}
