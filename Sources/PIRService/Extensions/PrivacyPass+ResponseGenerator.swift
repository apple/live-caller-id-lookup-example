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

    public func response(from _: Request, context: some RequestContext) throws -> Response {
        let body = context.allocator.buffer(string: localizedDescription)
        return Response(status: status, body: ResponseBody(byteBuffer: body))
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
