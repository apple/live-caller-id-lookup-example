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
