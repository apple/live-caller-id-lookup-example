// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import Foundation
import Hummingbird
import SwiftProtobuf

extension Request {
    func decodeProto<Msg: Message>(as _: Msg.Type, context: some RequestContext) async throws -> Msg {
        let body = try await body.collect(upTo: context.maxUploadSize)
        return try Msg(serializedData: Data(buffer: body, byteTransferStrategy: .noCopy))
    }
}
