// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import Hummingbird
import HummingbirdTesting
@testable import PIRService
import SwiftProtobuf

public extension TestClientProtocol {
    @discardableResult
    func execute<Return>(
        uri: String,
        userIdentifier: UserIdentifier,
        message: some Message,
        testCallback: @escaping (TestResponse) async throws -> Return = { $0 }) async throws -> Return
    {
        let bodyBuffer = try ByteBuffer(data: message.serializedData())
        let headers: HTTPFields = [.userIdentifier: userIdentifier.identifier]
        let response = try await executeRequest(uri: uri, method: .post, headers: headers, body: bodyBuffer)
        return try await testCallback(response)
    }
}
