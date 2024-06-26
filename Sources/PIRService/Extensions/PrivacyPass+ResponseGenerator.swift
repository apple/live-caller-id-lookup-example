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

extension PrivacyPass.PrivacyPassError: HTTPResponseError {
    var status: HTTPTypes.HTTPResponse.Status {
        .badRequest
    }

    var headers: HTTPTypes.HTTPFields {
        [:]
    }

    func body(allocator: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        allocator.buffer(string: localizedDescription)
    }
}

extension TokenIssuerDirectory: ResponseGenerator {
    func response(from request: HummingbirdCore.Request, context: some RequestContext) throws -> Response {
        try context.responseEncoder.encode(self, from: request, context: context)
    }
}

extension PrivacyPass.TokenResponse: ResponseGenerator {
    func response(from _: HummingbirdCore.Request, context: some RequestContext) throws -> Response {
        let body = context.allocator.buffer(bytes: bytes())
        return Response(
            status: .ok,
            headers: [.contentType: "application/private-token-response"],
            body: .init(byteBuffer: body))
    }
}

extension PrivacyPass.PublicKey: ResponseGenerator {
    func response(from _: Request, context: some RequestContext) throws -> Response {
        let body = try context.allocator.buffer(bytes: spki())
        return Response(status: .ok, body: .init(byteBuffer: body))
    }
}
