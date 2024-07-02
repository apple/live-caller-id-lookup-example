// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

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
public struct TokenRequest: Equatable {
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
            throw PrivacyPassError.invalidTokenRequestSize
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
