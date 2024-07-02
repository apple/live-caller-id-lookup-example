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
import PrivacyPass

extension PrivacyPass.PrivacyPassError: @retroactive HTTPResponseError {
    public var status: HTTPTypes.HTTPResponse.Status {
        // Default to `.badRequest` however, some erros types are specified to return HTTP 422.
        // From: https://www.rfc-editor.org/rfc/rfc9578#name-issuer-to-client-response-2
        // If any of these conditions are not met, the Issuer MUST return an HTTP 422 (Unprocessable Content) error to
        // the Client.
        switch self {
        case .invalidTokenKeyId:
            .unprocessableContent
        case .invalidTokenRequestBlindedMessageSize:
            .unprocessableContent
        case .invalidTokenType:
            .unprocessableContent
        default:
            .badRequest
        }
    }

    public var headers: HTTPTypes.HTTPFields {
        [:]
    }

    public func body(allocator: NIOCore.ByteBufferAllocator) -> NIOCore.ByteBuffer? {
        allocator.buffer(string: localizedDescription)
    }
}

extension TokenIssuerDirectory: @retroactive ResponseGenerator {
    public func response(from request: HummingbirdCore.Request, context: some RequestContext) throws -> Response {
        try context.responseEncoder.encode(self, from: request, context: context)
    }
}

extension PrivacyPass.TokenResponse: @retroactive ResponseGenerator {
    public func response(from _: HummingbirdCore.Request, context: some RequestContext) throws -> Response {
        let body = context.allocator.buffer(bytes: bytes())
        return Response(
            status: .ok,
            headers: [.contentType: "application/private-token-response"],
            body: .init(byteBuffer: body))
    }
}

extension PrivacyPass.PublicKey: @retroactive ResponseGenerator {
    public func response(from _: Request, context: some RequestContext) throws -> Response {
        let body = try context.allocator.buffer(bytes: spki())
        return Response(status: .ok, body: .init(byteBuffer: body))
    }
}
