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
import HomomorphicEncryption
import HomomorphicEncryptionProtobuf
import Hummingbird
import Logging
import NIO
import PrivateInformationRetrieval

struct AppContext: IdentifiedRequestContext, AuthenticatedRequestContext, RequestContext {
    var coreContext: CoreRequestContextStorage
    var userIdentifier: UserIdentifier
    var userTier: UserTier

    init(source: ApplicationRequestContextSource) {
        self.coreContext = .init(source: source)
        self.userIdentifier = UserIdentifier(identifier: "")
        self.userTier = .tier1
    }
}

func buildExampleUsecase() throws -> Usecase {
    typealias ServerType = KeywordPirServer<MulPirServer<Bfv<UInt64>>>
    let databaseRows = (0..<100)
        .map { KeywordValuePair(keyword: [UInt8](String($0).utf8), value: [UInt8](String($0).utf8)) }
    let context: Context<ServerType.Scheme> = try .init(parameter: .init(from: .n_4096_logq_27_28_28_logt_4))
    let config = KeywordPirConfig(
        dimensionCount: 2,
        cuckooTableConfig: .defaultKeywordPir(maxSerializedBucketSize: context.bytesPerPlaintext),
        unevenDimensions: false)
    let processed = try ServerType.process(
        database: databaseRows,
        config: config,
        with: context)
    let shard = try ServerType(context: context, processed: processed)
    return PirUsecase(context: context, keywordParams: config.parameter, shards: [shard])
}

func loadUsecase(from path: String, shardCount: Int) throws -> Usecase {
    do {
        return try PirUsecase<MulPirServer<Bfv<UInt32>>>(from: path, shardCount: shardCount)
    } catch {
        return try PirUsecase<MulPirServer<Bfv<UInt64>>>(from: path, shardCount: shardCount)
    }
}

func buildApplication(
    configuration: ApplicationConfiguration = .init(),
    usecaseStore: UsecaseStore = UsecaseStore(),
    privacyPassState: PrivacyPassState<UserAuthenticator>? = nil,
    evaluationKeyStore: some PersistDriver = MemoryPersistDriver()) async throws -> some ApplicationProtocol
{
    let router = Router(context: AppContext.self)
    router.middlewares.add(LogRequestsMiddleware(.info, includeHeaders: .none))

    let pirServiceController = PIRServiceController(usecases: usecaseStore, evaluationKeyStore: evaluationKeyStore)
    let pirGroup = router.group()

    if let privacyPassState {
        let controller = PrivacyPassController(state: privacyPassState)
        controller.addRoutes(to: router.group())
        let userTierAuthenticator = AuthenticateUserTierMiddleware(AppContext.self, state: privacyPassState)
        pirGroup.add(middleware: userTierAuthenticator)
    }

    pirServiceController.addRoutes(to: pirGroup)

    var application = Application(router: router, configuration: configuration)
    application.addServices(evaluationKeyStore)

    return application
}
