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
import HomomorphicEncryptionProtobuf
import Hummingbird
import PrivateInformationRetrievalProtobuf

struct PIRServiceController {
    let usecases: UsecaseStore
    let evaluationKeyStore: PersistDriver

    static func persistKey(user: UserIdentifier, configHash: Data) -> String {
        "\(user.identifier)/\(configHash.base64EncodedString())"
    }

    func addRoutes(to group: RouterGroup<AppContext>) {
        group.add(middleware: ExtractUserIdentifierMiddleware())
            .post("/key", use: key)
            .post("/config", use: config)
            .post("/queries", use: queries)
    }

    @Sendable
    func key(_ request: Request, context: AppContext) async throws -> Response {
        let evaluationKeys = try await request.decodeProto(
            as: Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKeys.self,
            context: context)
        for evaluationKey in evaluationKeys.keys {
            guard evaluationKey.hasMetadata, evaluationKey.hasEvaluationKey else {
                throw HTTPError(.badRequest, message: "Evaluation key has unset fields")
            }

            let key = Self.persistKey(user: context.userIdentifier, configHash: evaluationKey.metadata.identifier)
            try await evaluationKeyStore.set(key: key, value: Protobuf(evaluationKey))
        }
        return .init(status: .ok)
    }

    @Sendable
    func config(_ request: Request, context: AppContext) async throws -> some ResponseGenerator {
        context.logger.info("Tier = \(context.userTier)")
        let configRequest = try await request.decodeProto(
            as: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigRequest.self,
            context: context)
        let requestedUsecases = if configRequest.usecases.isEmpty {
            await usecases.store
        } else {
            await usecases.get(names: configRequest.usecases)
        }

        let configs = try requestedUsecases.mapValues { usecase in
            try usecase.config()
        }

        let keyConfigs = try requestedUsecases.values.map { try $0.evaluationKeyConfig() }
        let keyStatusesSequence = keyConfigs.async.map { keyConfig in
            let keyConfigHash = try keyConfig.sha256()
            let key = Self.persistKey(user: context.userIdentifier, configHash: keyConfigHash)
            let storedEvaluationKey = try await evaluationKeyStore.get(
                key: key,
                as: Protobuf<Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey>.self)
            return Apple_SwiftHomomorphicEncryption_Api_Shared_V1_KeyStatus.with { keyStatus in
                keyStatus.timestamp = storedEvaluationKey?.message.metadata.timestamp ?? 0
                keyStatus.keyConfig = keyConfig
            }
        }

        let keyStatuses: [Apple_SwiftHomomorphicEncryption_Api_Shared_V1_KeyStatus] =
            try await .init(keyStatusesSequence)
        return Protobuf(Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigResponse.with { configResponse in
            configResponse.configs = configs
            configResponse.keyInfo = keyStatuses
        })
    }

    @Sendable
    func queries(_ request: Request, context: AppContext) async throws -> some ResponseGenerator {
        let startTime = Date.now
        let requests = try await request.decodeProto(
            as: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Requests.self,
            context: context)

        defer {
            let duration = Date.now.timeIntervalSince(startTime)
            context.logger.info("usecase=\(requests.requests.map(\.usecase)), duration=\(duration * 1000)ms")
        }

        let responsesSequence = requests.requests.async.map { request in
            var evaluationKey: Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey?
            if request.pirRequest.hasEvaluationKey {
                evaluationKey = request.pirRequest.evaluationKey
            } else {
                let evaluationKeyConfigHash = request.pirRequest.evaluationKeyMetadata.identifier
                let evaluationKeyStoreKey = Self.persistKey(
                    user: context.userIdentifier,
                    configHash: evaluationKeyConfigHash)
                evaluationKey = try await evaluationKeyStore.get(
                    key: evaluationKeyStoreKey,
                    as: Protobuf<Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey>.self)?.message
            }

            guard let evaluationKey else {
                throw HTTPError(.badRequest, message: "Evaluation key not found")
            }

            guard let usecase = await usecases.get(name: request.usecase) else {
                throw HTTPError(.badRequest, message: "Unknown usecase: \(request.usecase)")
            }
            return try await usecase.process(request: request, evaluationKey: evaluationKey)
        }

        let responses: [Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Response] = try await .init(responsesSequence)
        return Protobuf(Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Responses.with { apiResponses in
            apiResponses.responses = responses
        })
    }
}
