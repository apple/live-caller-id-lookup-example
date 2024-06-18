// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

extension PrivacyPass {
    /*
     struct {
       uint16_t token_type = 0x0002; /* Type Blind RSA (2048-bit) */
       uint8_t truncated_token_key_id;
       uint8_t blinded_msg[Nk];
     } TokenRequest;
     */
    struct TokenRequest: Equatable {
        static let blindedMsgSize = TokenTypeBlindRSANK
        static let sizeInBytes = MemoryLayout<UInt16>.size + MemoryLayout<UInt8>.size + blindedMsgSize

        let tokenType: UInt16
        let truncatedTokenKeyId: UInt8
        let blindedMsg: [UInt8]

        init(tokenType: UInt16, truncatedTokenKeyId: UInt8, blindedMsg: [UInt8]) {
            self.tokenType = tokenType
            self.truncatedTokenKeyId = truncatedTokenKeyId
            self.blindedMsg = blindedMsg
        }

        init<C: Collection<UInt8>>(from bytes: C) throws {
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

        func bytes() -> [UInt8] {
            var bytes: [UInt8] = []
            bytes.reserveCapacity(Self.sizeInBytes)
            bytes.append(contentsOf: tokenType.bigEndianBytes)
            bytes.append(truncatedTokenKeyId)
            bytes.append(contentsOf: blindedMsg)
            return bytes
        }
    }
}
