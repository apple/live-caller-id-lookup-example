// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

// MARK: Extension of SystemRandomNumberGenerator

extension RandomNumberGenerator {
    @inlinable
    mutating func fill(_ bufferPointer: UnsafeMutableRawBufferPointer) {
        let size = MemoryLayout<UInt64>.size
        for i in stride(from: bufferPointer.startIndex, through: bufferPointer.endIndex &- size, by: size) {
            var random = next()
            withUnsafeBytes(of: &random) { randomBufferPointer in
                let rebased = UnsafeMutableRawBufferPointer(rebasing: bufferPointer[i..<(i &+ size)])
                rebased.copyMemory(from: randomBufferPointer)
            }
        }

        var remainingSlice = bufferPointer.suffix(from: (bufferPointer.count / size) * size)
        if !remainingSlice.isEmpty {
            var random = next()
            withUnsafeBytes(of: &random) { randomBufferPointer in
                for (sliceIndex, randomIndex) in zip(remainingSlice.indices, randomBufferPointer.indices) {
                    remainingSlice[sliceIndex] = randomBufferPointer[randomIndex]
                }
            }
        }
    }
}

// MARK: Provide conversion to BigEndian bytes

extension FixedWidthInteger {
    var bigEndianBytes: [UInt8] {
        var bigEndian = bigEndian
        return Swift.withUnsafeBytes(of: &bigEndian) { buffer in
            [UInt8](buffer)
        }
    }

    @inlinable
    init(bigEndianBytes: some Collection<UInt8>) {
        var bigEndian = Self.zero
        withUnsafeMutableBytes(of: &bigEndian) { buffer in
            buffer.copyBytes(from: bigEndianBytes)
        }
        self.init(bigEndian: bigEndian)
    }
}
