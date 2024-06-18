// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

#if canImport(Darwin)
import Foundation
#else
// Foundation.URL is not Sendable
@preconcurrency import Foundation
#endif
import Hummingbird

struct PrivacyPassController<UserAuthenticator: UserTokenAuthenticator> {
    let state: PrivacyPassState<UserAuthenticator>

    func addRoutes(to group: RouterGroup<AppContext>) {
        group.get("/.well-known/private-token-issuer-directory", use: tokenIssuerDirectory)
        group.get("/token-key-for-user-token", use: tokenKeyForUserToken)
        group.post("/issue", use: issueToken)
    }

    func authenticateUserToken(request: Request) async throws -> UserTier {
        guard let userToken = request.headers.bearerToken,
              let userTier = try await state.userAuthenticator.authenticate(userToken: userToken)
        else {
            throw HTTPError(.unauthorized)
        }
        return userTier
    }

    @Sendable
    func tokenIssuerDirectory(request _: Request, context _: AppContext) async throws -> TokenIssuerDirectory {
        let tokenKeys = try await state.issuers.values.map(\.privateKey.publicKey).map { publicKey in
            let spki = try publicKey.spki()
            return TokenKey(
                tokenType: PrivacyPass.TokenTypeBlindRSA,
                tokenKeyBase64Url: spki.base64URLEncodedString(),
                notBefore: nil)
        }
        #if canImport(Darwin)
        return TokenIssuerDirectory(issuerRequestUri: state.issuerRequestUri, tokenKeys: tokenKeys)
        #else
        return await TokenIssuerDirectory(issuerRequestUri: state.issuerRequestUri, tokenKeys: tokenKeys)
        #endif
    }

    @Sendable
    func tokenKeyForUserToken(request: Request, context _: AppContext) async throws -> PrivacyPass.PublicKey {
        let userTier = try await authenticateUserToken(request: request)
        guard let issuer = await state.issuers[userTier] else {
            throw HTTPError(.internalServerError, message: "Could not find issuer for tier \(userTier)")
        }
        return issuer.publicKey
    }

    @Sendable
    func issueToken(request: Request, context _: AppContext) async throws -> PrivacyPass.TokenResponse {
        let userTier = try await authenticateUserToken(request: request)
        // decode tokenRequest
        var tokenRequestByteBuffer = try await request.body.collect(upTo: PrivacyPass.TokenRequest.sizeInBytes)
        guard let tokenRequestBytes = tokenRequestByteBuffer.readBytes(length: PrivacyPass.TokenRequest.sizeInBytes)
        else {
            throw PrivacyPass.PrivacyPassError.invalidTokenRequestSize
        }
        let tokenRequest = try PrivacyPass.TokenRequest(from: tokenRequestBytes)

        guard let issuer = await state.issuers[userTier] else {
            throw HTTPError(.internalServerError, message: "Could not find issuer for tier \(userTier)")
        }

        return try issuer.issue(request: tokenRequest)
    }
}
