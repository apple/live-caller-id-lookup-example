// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import HTTPTypes
import Hummingbird

enum UserTier: Equatable, CaseIterable, Hashable, Codable {
    case tier1
    case tier2
    case tier3
}

protocol AuthenticatedRequestContext: RequestContext {
    var userTier: UserTier { get set }
}

struct AuthenticateUserTierMiddleware<
    Context: AuthenticatedRequestContext,
    Authenticator: UserTokenAuthenticator
>: RouterMiddleware {
    let state: PrivacyPassState<Authenticator>

    init(_: Context.Type, state: PrivacyPassState<Authenticator>) {
        self.state = state
    }

    func handle(_ input: Request, context: Context,
                next: (Request, Context) async throws -> Response) async throws -> Response
    {
        context.logger.info("Authenticating request")
        var context = context
        guard let token = try input.headers.privateToken() else {
            throw HTTPError(.unauthorized, message: "No private token")
        }

        guard let truncatedKeyId = token.tokenKeyId.last,
              let tieredVerifier = await state.verifiers[truncatedKeyId]
        else {
            throw HTTPError(.unauthorized, message: "No token key found with key id: \(token.tokenKeyId)")
        }

        guard try tieredVerifier.verifier.verify(token: token) else {
            throw HTTPError(.unauthorized, message: "Token did not pass verification")
        }

        context.userTier = tieredVerifier.tier
        return try await next(input, context)
    }
}
