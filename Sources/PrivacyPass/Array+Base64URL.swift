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
