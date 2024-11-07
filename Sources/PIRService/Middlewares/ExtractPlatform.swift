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

import Foundation
import HTTPTypes
import Hummingbird
import Util

protocol PlatformRequestContext: RequestContext {
    var platform: Platform? { get set }
}

/// Middleware that extracts the platform from the 'User-Agent' header
struct ExtractPlatformMiddleware<Context: PlatformRequestContext>: RouterMiddleware {
    func handle(
        _ input: Request,
        context: Context,
        next: (Request, Context) async throws -> Response) async throws -> Response
    {
        var context = context
        guard let userAgent = input.headers[.userAgent] else {
            throw HTTPError(.badRequest, message: "Missing 'User-Agent' header")
        }
        context.platform = Platform(userAgent: userAgent)
        return try await next(input, context)
    }
}
