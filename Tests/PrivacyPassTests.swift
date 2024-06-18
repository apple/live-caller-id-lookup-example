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
@testable import PIRService
import TestUtil
import XCTest

class PrivacyPassTests: XCTestCase {
    func testConvertAndLoadPublicKey() throws {
        let privateKey = try PrivacyPass.PrivateKey()
        let spki = try privateKey.publicKey.spki()
        _ = try PrivacyPass.PublicKey(fromSPKI: spki)
    }

    func testVectors() throws {
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
            let privateKey = try PrivacyPass
                .PrivateKey(privateKey: _RSA.BlindSigning.PrivateKey(pemRepresentation: privateKeyPEM))
            // verify public key is correctly encoded
            let pkS = try unhex(testVector.pkS)
            let spki = try privateKey.publicKey.spki()
            XCTAssertEqual(spki, pkS)
            // verify we can load the public key directly from SPKI
            _ = try PrivacyPass.PublicKey(fromSPKI: pkS)
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
            // verify token validity
            let tokenBytes = try unhex(testVector.token)
            let token = try PrivacyPass.Token(from: tokenBytes)
            XCTAssertEqual(token.bytes(), tokenBytes)
            let verifier = PrivacyPass.Verifier(publicKey: privateKey.publicKey)
            let verified = try verifier.verify(token: token)
            XCTAssertTrue(verified)
        }
    }
}
