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

/// Privacy Pass token response.
///
/// This the token response struct.
/// ```
/// struct {
///   uint8_t blind_sig[Nk];
/// } TokenResponse;
/// ```
public struct TokenResponse: Equatable, Sendable {
    static let sizeInBytes = TokenTypeBlindRSANK

    /// The blind signature of the token.
    public let blindSignature: [UInt8]

    /// Initialize a token response.
    /// - Parameter blindSignature: The blind signature to use in the response.
    public init(blindSignature: [UInt8]) {
        self.blindSignature = blindSignature
    }

    /// Load a Private Pass Token response from bytes.
    /// - Parameter bytes: Collection of bytes representing a token reponse.
    public init(from bytes: some Collection<UInt8>) throws {
        guard bytes.count == Self.sizeInBytes else {
            throw PrivacyPassError(code: .invalidTokenResponseSize)
        }
        self.blindSignature = Array(bytes)
    }

    /// Convert to byte array.
    /// - Returns: A binary representation of the token response.
    public func bytes() -> [UInt8] {
        blindSignature
    }
}
