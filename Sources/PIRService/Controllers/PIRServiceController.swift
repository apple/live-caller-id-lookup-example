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
            as: Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKeys.self,
            context: context)
        for evaluationKey in evaluationKeys.keys {
            guard evaluationKey.hasMetadata, evaluationKey.hasEvaluationKey else {
                throw HTTPError(.badRequest, message: "Evaluation key has unset fields")
            }

            let key = Self.persistKey(user: context.userIdentifier, configHash: evaluationKey.metadata.identifier)
            try await evaluationKeyStore.set(key: key, value: evaluationKey.serializedData())
        }
        return .init(status: .ok)
    }

    @Sendable
    func config(_ request: Request, context: AppContext) async throws -> some ResponseGenerator {
        context.logger.info("Tier = \(context.userTier)")
        let configRequest = try await request.decodeProto(
            as: Apple_SwiftHomomorphicEncryption_Api_V1_ConfigRequest.self,
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
                as: Data.self).map { try Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey(serializedData: $0) }
            return Apple_SwiftHomomorphicEncryption_Api_V1_KeyStatus.with { keyStatus in
                keyStatus.timestamp = storedEvaluationKey?.metadata.timestamp ?? 0
                keyStatus.keyConfig = keyConfig
            }
        }

        let keyStatuses: [Apple_SwiftHomomorphicEncryption_Api_V1_KeyStatus] = try await .init(keyStatusesSequence)
        return Protobuf(Apple_SwiftHomomorphicEncryption_Api_V1_ConfigResponse.with { configResponse in
            configResponse.configs = configs
            configResponse.keyInfo = keyStatuses
        })
    }

    @Sendable
    func queries(_ request: Request, context: AppContext) async throws -> some ResponseGenerator {
        let startTime = Date.now
        let requests = try await request.decodeProto(
            as: Apple_SwiftHomomorphicEncryption_Api_V1_Requests.self,
            context: context)

        defer {
            let duration = Date.now.timeIntervalSince(startTime)
            context.logger.info("usecase=\(requests.requests.map(\.usecase)), duration=\(duration * 1000)ms")
        }

        let responsesSequence = requests.requests.async.map { request in
            var evaluationKey: Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey?
            if request.pirRequest.hasEvaluationKey {
                evaluationKey = request.pirRequest.evaluationKey
            } else {
                let evaluationKeyConfigHash = request.pirRequest.evaluationKeyMetadata.identifier
                let evaluationKeyStoreKey = Self.persistKey(
                    user: context.userIdentifier,
                    configHash: evaluationKeyConfigHash)
                evaluationKey = try await evaluationKeyStore.get(
                    key: evaluationKeyStoreKey,
                    as: Data.self).map { try Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey(serializedData: $0) }
            }

            guard let evaluationKey else {
                throw HTTPError(.badRequest, message: "Evaluation key not found")
            }

            guard let usecase = await usecases.get(name: request.usecase) else {
                throw HTTPError(.badRequest, message: "Unknown usecase: \(request.usecase)")
            }
            return try await usecase.process(request: request, evaluationKey: evaluationKey)
        }

        let responses: [Apple_SwiftHomomorphicEncryption_Api_V1_Response] = try await .init(responsesSequence)
        return Protobuf(Apple_SwiftHomomorphicEncryption_Api_V1_Responses.with { apiResponses in
            apiResponses.responses = responses
        })
    }
}
