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

public extension [UInt8] {
    /// Initialize a byte array from base64url encoded string.
    /// - Parameter string: base64url encoded string.
    init?(base64URLEncoded string: String) {
        let base64Encoded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        self.init(base64Encoded: base64Encoded)
    }

    /// Initialize a byte array from base64 encoded string.
    /// - Parameter base64Encoded: base64 encoded string.
    init?(base64Encoded: String) {
        guard let data = Data(base64Encoded: base64Encoded) else {
            return nil
        }
        self.init(data)
    }

    /// Return a base64url encoded version of the array.
    /// - Returns: Valid base64url encoding fo the aray.
    func base64URLEncodedString() -> String {
        Data(self).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
