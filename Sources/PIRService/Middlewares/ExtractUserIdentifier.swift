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
import HTTPTypes
import Hummingbird

struct UserIdentifier: Equatable, Hashable {
    let identifier: String

    init() {
        self.identifier = UUID().uuidString
    }

    init(identifier: String) {
        self.identifier = identifier
    }
}

protocol IdentifiedRequestContext: RequestContext {
    var userIdentifier: UserIdentifier { get set }
}

/// Middleware that makes sure that the 'User-Identifier' header is set
struct ExtractUserIdentifierMiddleware<Context: IdentifiedRequestContext>: RouterMiddleware {
    func handle(
        _ input: Request,
        context: Context,
        next: (Request, Context) async throws -> Response) async throws -> Response
    {
        var context = context
        guard let userIdentifier = input.headers[.userIdentifier] else {
            throw HTTPError(.badRequest, message: "Missing 'User-Identifier' header")
        }
        context.userIdentifier = UserIdentifier(identifier: userIdentifier)
        return try await next(input, context)
    }
}

extension HTTPField.Name {
    // swiftlint:disable:next force_unwrapping
    static var userIdentifier: Self { Self("User-Identifier")! }
}
