// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import HTTPTypes
import PrivacyPass

extension HTTPFields {
    var bearerToken: String? {
        let prefix = "Bearer "
        guard let authorization = self[.authorization],
              authorization.hasPrefix(prefix)
        else {
            return nil
        }
        return String(authorization.dropFirst(prefix.count))
    }

    func privateToken() throws -> PrivacyPass.Token? {
        let prefix = "PrivateToken token="
        guard let authorization = self[.authorization],
              authorization.hasPrefix(prefix),
              let decoded = Array(base64URLEncoded: String(authorization.dropFirst(prefix.count)))
        else {
            return nil
        }

        return try .init(from: decoded)
    }
}
