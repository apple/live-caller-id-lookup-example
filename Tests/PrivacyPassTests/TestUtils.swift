// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import XCTest

public extension [UInt8] {
    init?(hexEncoded hexString: String) {
        // Ensure the string has an even number of characters
        guard hexString.count.isMultiple(of: 2) else {
            return nil
        }

        var data = Array()
        data.reserveCapacity(hexString.count / 2)
        var index = hexString.startIndex

        while index < hexString.endIndex {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let byte = UInt8(hexString[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil // Invalid hex string
            }
            index = nextIndex
        }

        self = data
    }

    func hexEncodedString() -> String {
        reduce(into: "") { $0 += String(format: "%02x", $1) }
    }
}

class TestUtilTests: XCTestCase {
    func testHexString() {
        XCTAssertEqual(Array(base64Encoded: "AAAA"), Array(hexEncoded: "000000"))
        XCTAssertEqual(Array(base64Encoded: "AAAB"), Array(hexEncoded: "000001"))
        let data = (0..<71).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
        let hexString = data.hexEncodedString()
        XCTAssertEqual(Array(hexEncoded: hexString), data)
    }
}
