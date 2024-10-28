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

/// Privacy Pass Token request.
///
/// This is the token request struct.
/// ```
/// struct {
///   uint16_t token_type = 0x0002; /* Type Blind RSA (2048-bit) */
///   uint8_t truncated_token_key_id;
///   uint8_t blinded_msg[Nk];
/// } TokenRequest;
/// ```
public struct TokenRequest: Equatable, Sendable {
    public static let blindedMsgSize = TokenTypeBlindRSANK
    public static let sizeInBytes = MemoryLayout<UInt16>.size + MemoryLayout<UInt8>.size + blindedMsgSize

    /// Token type.
    public let tokenType: UInt16
    /// Truncated Token Key identifier.
    public let truncatedTokenKeyId: UInt8
    /// Blinded message.
    public let blindedMsg: [UInt8]

    /// Initialize a token request.
    ///
    /// - Parameters:
    ///   - tokenType: Token type.
    ///   - truncatedTokenKeyId: Truncated token key identifier of the public key.
    ///   - blindedMsg: Blinded message
    /// - seealso: ``PreparedRequest/tokenRequest``.
    public init(tokenType: UInt16, truncatedTokenKeyId: UInt8, blindedMsg: [UInt8]) {
        self.tokenType = tokenType
        self.truncatedTokenKeyId = truncatedTokenKeyId
        self.blindedMsg = blindedMsg
    }

    /// Load a Private Pass Token request from bytes.
    /// - Parameter bytes: Collection of bytes representing a token request.
    public init<C: Collection<UInt8>>(from bytes: C) throws {
        guard bytes.count == Self.sizeInBytes else {
            throw PrivacyPassError(code: .invalidTokenRequestSize)
        }
        var offset = bytes.startIndex

        func extractBytes(count: Int) -> C.SubSequence {
            let end = bytes.index(offset, offsetBy: count)
            defer {
                offset = end
            }
            return bytes[offset..<end]
        }

        self.tokenType = UInt16(bigEndianBytes: extractBytes(count: MemoryLayout<UInt16>.size))
        self.truncatedTokenKeyId = bytes[offset]
        bytes.formIndex(after: &offset)
        self.blindedMsg = Array(extractBytes(count: Self.blindedMsgSize))
    }

    /// Convert to byte array.
    /// - Returns: A binary representation of the token request.
    public func bytes() -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(Self.sizeInBytes)
        bytes.append(contentsOf: tokenType.bigEndianBytes)
        bytes.append(truncatedTokenKeyId)
        bytes.append(contentsOf: blindedMsg)
        return bytes
    }
}
