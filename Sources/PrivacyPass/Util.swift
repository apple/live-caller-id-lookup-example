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
