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

struct TokenKey: Codable {
    enum CodingKeys: String, CodingKey {
        case tokenType = "token-type"
        case tokenKeyBase64Url = "token-key"
        case notBefore = "not-before"
    }

    let tokenType: UInt16
    let tokenKeyBase64Url: String
    let notBefore: UInt64?

    // swiftlint:disable:next discouraged_optional_collection
    var tokenKey: [UInt8]? {
        Array(base64URLEncoded: tokenKeyBase64Url)
    }
}

struct TokenIssuerDirectory: Codable {
    enum CodingKeys: String, CodingKey {
        case issuerRequestUri = "issuer-request-uri"
        case tokenKeys = "token-keys"
    }

    let issuerRequestUri: URL
    let tokenKeys: [TokenKey]

    func isValid(tokenKey: [UInt8], currentTime: () -> Date = Date.init) -> Bool {
        for key in tokenKeys where key.tokenType == PrivacyPass.TokenTypeBlindRSA {
            if tokenKey == key.tokenKey {
                if let notBefore = key.notBefore {
                    let now = Int(currentTime().timeIntervalSince1970)
                    guard now >= notBefore else {
                        return false
                    }
                }
                return true
            }
        }
        return false
    }
}
