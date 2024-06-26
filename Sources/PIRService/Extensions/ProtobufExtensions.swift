// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import Crypto
import Foundation
import HomomorphicEncryptionProtobuf
import Hummingbird
import SwiftProtobuf

/// Wrapper class for protobuf messages
struct Protobuf<Msg: Message>: ResponseGenerator {
    let message: Msg

    init(_ message: Msg) {
        self.message = message
    }

    func response(from _: HummingbirdCore.Request,
                  context: some RequestContext) throws -> Response
    {
        let serialized = try message.serializedData()
        let buffer = context.allocator.buffer(data: serialized)
        return Response(status: .ok, body: ResponseBody(byteBuffer: buffer))
    }
}

extension Message {
    func sha256() throws -> Data {
        let serialized = try serializedData()
        let digest = SHA256.hash(data: serialized)
        return Data(digest)
    }
}
