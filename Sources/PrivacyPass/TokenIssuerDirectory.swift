// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

#if canImport(Darwin)
import Foundation
#else
// Foundation.URL is not Sendable
@preconcurrency import Foundation
#endif

public struct TokenIssuerDirectory: Codable, Sendable {
    public struct TokenKey: Codable, Sendable {
        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case tokenType = "token-type"
            case tokenKeyBase64Url = "token-key"
            case notBefore = "not-before"
        }

        public let tokenType: UInt16
        public let tokenKeyBase64Url: String
        public let notBefore: UInt64?

        public init(tokenType: UInt16, tokenKeyBase64Url: String, notBefore: UInt64?) {
            self.tokenType = tokenType
            self.tokenKeyBase64Url = tokenKeyBase64Url
            self.notBefore = notBefore
        }

        // swiftlint:disable:next discouraged_optional_collection
        public var tokenKey: [UInt8]? {
            Array(base64URLEncoded: tokenKeyBase64Url)
        }
    }

    enum CodingKeys: String, CodingKey {
        case issuerRequestUri = "issuer-request-uri"
        case tokenKeys = "token-keys"
    }

    public let issuerRequestUri: URL
    public let tokenKeys: [TokenKey]

    public init(issuerRequestUri: URL, tokenKeys: [TokenKey]) {
        self.issuerRequestUri = issuerRequestUri
        self.tokenKeys = tokenKeys
    }

    public func isValid(tokenKey: [UInt8], currentTime: () -> Date = Date.init) -> Bool {
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
