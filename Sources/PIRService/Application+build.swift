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
    let context: Context<ServerType.Scheme> = try .init(encryptionParameters: .init(from: .n_4096_logq_27_28_28_logt_4))
    let config = try KeywordPirConfig(
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
