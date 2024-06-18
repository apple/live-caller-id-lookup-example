// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import HomomorphicEncryption
import Hummingbird
import PrivateInformationRetrieval

extension HomomorphicEncryption.HeError: @retroactive HTTPResponseError {
    public var status: HTTPResponse.Status {
        .badRequest
    }

    public var headers: HTTPFields {
        .init()
    }

    public func body(allocator: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        allocator.buffer(string: localizedDescription)
    }
}

extension PrivateInformationRetrieval.PirError: @retroactive HTTPResponseError {
    public var status: HTTPResponse.Status {
        .badRequest
    }

    public var headers: HTTPFields {
        .init()
    }

    public func body(allocator: NIOCore.ByteBufferAllocator) -> ByteBuffer? {
        allocator.buffer(string: localizedDescription)
    }
}
