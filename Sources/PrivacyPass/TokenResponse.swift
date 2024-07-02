// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

/// Privacy Pass token response.
///
/// This the token response struct.
/// ```
/// struct {
///   uint8_t blind_sig[Nk];
/// } TokenResponse;
/// ```
public struct TokenResponse: Equatable {
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
            throw PrivacyPassError.invalidTokenResponseSize
        }
        self.blindSignature = Array(bytes)
    }

    /// Convert to byte array.
    /// - Returns: A binary representation of the token response.
    public func bytes() -> [UInt8] {
        blindSignature
    }
}
