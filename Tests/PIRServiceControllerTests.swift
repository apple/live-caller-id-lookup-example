// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import HomomorphicEncryption
import HomomorphicEncryptionProtobuf
import Hummingbird
import HummingbirdTesting
@testable import PIRService
import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf
import XCTest

class PIRServiceControllerTests: XCTestCase {
    private static var exampleUsecase: Usecase {
        // swiftlint:disable:next force_try
        try! buildExampleUsecase()
    }

    func testNoUserIdentifier() async throws {
        let app = try await buildApplication()
        try await app.test(.live) { client in
            try await client.execute(uri: "/key", method: .post) { response in
                XCTAssertEqual(response.status, .badRequest)
                XCTAssertEqual(String(buffer: response.body), "Missing 'User-Identifier' header")
            }
        }
    }

    func testKeyUpload() async throws {
        let evaluationKeyStore = MemoryPersistDriver()
        let app = try await buildApplication(evaluationKeyStore: evaluationKeyStore)
        let user = UserIdentifier()

        let evalKeyMetadata = Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKeyMetadata.with { metadata in
            metadata.timestamp = UInt64(Date.now.timeIntervalSince1970)
            metadata.identifier = Data("test".utf8)
        }
        let evalKey = Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey.with { evalKey in
            evalKey.metadata = evalKeyMetadata
            evalKey.evaluationKey = Apple_SwiftHomomorphicEncryption_V1_SerializedEvaluationKey()
        }
        let evaluationKeys = Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKeys.with { evalKeys in
            evalKeys.keys = [evalKey]
        }
        try await app.test(.live) { client in
            try await client
                .execute(uri: "/key", userIdentifier: user, message: evaluationKeys) { response in
                    XCTAssertEqual(response.status, .ok)
                }

            // make sure the evaluation key was persisted
            let persistKey = PIRServiceController.persistKey(user: user, configHash: evalKeyMetadata.identifier)
            let storedKey = try await evaluationKeyStore.get(
                key: persistKey,
                as: Data.self).map { try Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey(serializedData: $0) }
            XCTAssertEqual(storedKey, evalKey)
        }
    }

    func testConfigFetch() async throws {
        let usecaseStore = UsecaseStore()
        let exampleUsecase = Self.exampleUsecase
        await usecaseStore.set(name: "test", usecase: exampleUsecase)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        let user = UserIdentifier()

        let configRequest = Apple_SwiftHomomorphicEncryption_Api_V1_ConfigRequest.with { configReq in
            configReq.usecases = ["test"]
        }
        try await app.test(.live) { client in
            try await client.execute(uri: "/config", userIdentifier: user, message: configRequest) { response in
                XCTAssertEqual(response.status, .ok)
                let configResponse = try response
                    .message(as: Apple_SwiftHomomorphicEncryption_Api_V1_ConfigResponse.self)
                try XCTAssertEqual(configResponse.configs["test"], exampleUsecase.config())
                try XCTAssertEqual(configResponse.keyInfo[0].keyConfig, exampleUsecase.evaluationKeyConfig())
            }
        }
    }

    func testRequest() async throws {
        typealias Scheme = Bfv<UInt64>
        let usecaseStore = UsecaseStore()
        let exampleUsecase = Self.exampleUsecase
        await usecaseStore.set(name: "test", usecase: exampleUsecase)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        let user = UserIdentifier()
        // swiftlint:disable:next closure_body_length
        try await app.test(.live) { client in
            let context: Context<Scheme> = try .init(parameter: .init(from: .n_4096_logq_27_28_28_logt_4))

            // MARK: get configuration

            var config = Apple_SwiftHomomorphicEncryption_Api_V1_PIRConfig()
            var evaluationKeyConfig = Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig()

            try await client.execute(
                uri: "/config",
                userIdentifier: user,
                message: Apple_SwiftHomomorphicEncryption_Api_V1_ConfigRequest())
            { response in
                XCTAssertEqual(response.status, .ok)
                let configResponse = try response
                    .message(as: Apple_SwiftHomomorphicEncryption_Api_V1_ConfigResponse.self)

                config = try XCTUnwrap(configResponse.configs["test"]).pirConfig
                evaluationKeyConfig = configResponse.keyInfo[0].keyConfig
            }

            let shardConfig = config.shardConfigs[0]
            let keywordConfig: KeywordPirConfig = .init(
                dimensionCount: shardConfig.dimensions.count,
                cuckooTableConfig: CuckooTableConfig
                    .defaultKeywordPir(maxSerializedBucketSize: context.bytesPerPlaintext),
                unevenDimensions: false)
            let pirParameter = shardConfig.native(batchSize: Int(config.batchSize))
            let keywordPirClient: KeywordPirClient<MulPirClient<Scheme>> = .init(
                keywordParameter: keywordConfig.parameter,
                pirParameter: pirParameter,
                context: context)

            // MARK: upload evaluation key

            let secretKey = try Scheme.generateSecretKey(context: context)
            let evaluationKey = try keywordPirClient.generateEvaluationKey(using: secretKey)

            let serializedEvalKey = evaluationKey.serialize().proto()
            let evalKeyMetadata = try Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKeyMetadata.with { metadata in
                metadata.timestamp = UInt64(Date.now.timeIntervalSince1970)
                metadata.identifier = try evaluationKeyConfig.sha256()
            }
            let evalKey = Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey.with { evalKey in
                evalKey.metadata = evalKeyMetadata
                evalKey.evaluationKey = serializedEvalKey
            }
            let evaluationKeys = Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKeys.with { evalKeys in
                evalKeys.keys = [evalKey]
            }

            try await client.execute(uri: "/key", userIdentifier: user, message: evaluationKeys) { response in
                XCTAssertEqual(response.status, .ok)
            }

            // MARK: query

            let queryKeyword = [UInt8]("23".utf8)

            let query = try keywordPirClient.generateQuery(at: queryKeyword, using: secretKey)

            let pirRequest = Apple_SwiftHomomorphicEncryption_Api_V1_PIRRequest.with { pirRequest in
                pirRequest.shardIndex = 0
                pirRequest.query = query.proto()
                pirRequest.evaluationKeyMetadata = evalKeyMetadata
                // TODO: fill other fields?
            }
            let request = Apple_SwiftHomomorphicEncryption_Api_V1_Request.with { request in
                request.usecase = "test"
                request.pirRequest = pirRequest
            }
            let requests = Apple_SwiftHomomorphicEncryption_Api_V1_Requests.with { requests in
                requests.requests = [request]
            }

            var pirResponse = Apple_SwiftHomomorphicEncryption_Api_V1_PIRResponse()
            try await client
                .execute(uri: "/queries", userIdentifier: user, message: requests) { response in
                    XCTAssertEqual(response.status, .ok)
                    let responses = try response.message(as: Apple_SwiftHomomorphicEncryption_Api_V1_Responses.self)
                    pirResponse = responses.responses[0].pirResponse
                }

            // MARK: decrypt response

            let response = try pirResponse.native(context: context)
            let result = try keywordPirClient.decrypt(response: response, at: queryKeyword, using: secretKey)

            XCTAssertEqual(result, queryKeyword)
        }
    }
}
