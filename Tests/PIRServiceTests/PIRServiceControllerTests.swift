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

    private static func buildExampleUsecase() throws -> Usecase {
        typealias ServerType = KeywordPirServer<MulPirServer<Bfv<UInt64>>>
        let databaseRows = (0..<100)
            .map { KeywordValuePair(keyword: [UInt8](String($0).utf8), value: [UInt8](String($0).utf8)) }
        let context: Context<ServerType.Scheme> =
            try .init(encryptionParameters: .init(from: .n_4096_logq_27_28_28_logt_4))
        let config = try KeywordPirConfig(
            dimensionCount: 2,
            cuckooTableConfig: .defaultKeywordPir(maxSerializedBucketSize: context.bytesPerPlaintext),
            unevenDimensions: false, keyCompression: .noCompression)
        let processed = try ServerType.process(
            database: databaseRows,
            config: config,
            with: context)
        let shard = try ServerType(context: context, processed: processed)
        return PirUsecase(context: context, keywordParams: config.parameter, shards: [shard])
    }

    func testNoUserIdentifier() async throws {
        // Error message returned by Hummingbird
        struct ErrorMessage: Codable {
            // swiftlint:disable:next nesting
            struct Details: Codable {
                let message: String
            }

            let error: Details
        }

        let app = try await buildApplication()
        try await app.test(.live) { client in
            try await client.execute(uri: "/key", method: .post) { response in
                let errorMessage = try JSONDecoder().decode(ErrorMessage.self, from: response.body)
                XCTAssertEqual(errorMessage.error.message, "Missing 'User-Identifier' header")
            }
        }
    }

    func testKeyUpload() async throws {
        let evaluationKeyStore = MemoryPersistDriver()
        let app = try await buildApplication(evaluationKeyStore: evaluationKeyStore)
        let user = UserIdentifier()

        let evalKeyMetadata = Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKeyMetadata.with { metadata in
            metadata.timestamp = UInt64(Date.now.timeIntervalSince1970)
            metadata.identifier = Data("test".utf8)
        }
        let evalKey = Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey.with { evalKey in
            evalKey.metadata = evalKeyMetadata
            evalKey.evaluationKey = Apple_SwiftHomomorphicEncryption_V1_SerializedEvaluationKey()
        }
        let evaluationKeys = Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKeys.with { evalKeys in
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
                as: Protobuf<Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey>.self)
            XCTAssertEqual(storedKey?.message, evalKey)
        }
    }

    func testConfigFetch() async throws {
        let usecaseStore = UsecaseStore()
        let exampleUsecase = Self.exampleUsecase
        await usecaseStore.set(name: "test", usecase: exampleUsecase)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        let user = UserIdentifier()

        let configRequest = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigRequest.with { configReq in
            configReq.usecases = ["test"]
        }
        try await app.test(.live) { client in
            try await client.execute(uri: "/config", userIdentifier: user, message: configRequest) { response in
                XCTAssertEqual(response.status, .ok)
                let configResponse = try response
                    .message(as: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigResponse.self)
                try XCTAssertEqual(configResponse.configs["test"], exampleUsecase.config())
                try XCTAssertEqual(configResponse.keyInfo[0].keyConfig, exampleUsecase.evaluationKeyConfig())
            }
        }
    }

    func testCompressedConfigFetch() async throws {
        // Mock usecase that has a large config with 10K randomized shardConfigs.
        struct TestUseCaseWithLargeConfig: Usecase {
            init() {
                let shardConfigs = (0..<10000).map { _ in
                    Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRShardConfig.with { shardConfig in
                        shardConfig.numEntries = UInt64.random(in: 0..<1000)
                        shardConfig.entrySize = UInt64.random(in: 0..<1000)
                        shardConfig.dimensions = [UInt64.random(in: 0..<100), UInt64.random(in: 0..<100)]
                    }
                }

                self.randomConfig = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Config.with { config in
                    config.pirConfig = .with { pirConfig in
                        pirConfig.shardConfigs = shardConfigs
                    }
                }
            }

            let randomConfig: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Config

            func config() throws -> Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Config {
                randomConfig
            }

            func evaluationKeyConfig() throws -> Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig {
                Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig()
            }

            func process(
                request _: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Request,
                evaluationKey _: Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey) async throws
                -> Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Response
            {
                Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Response()
            }
        }

        let usecaseStore = UsecaseStore()
        let exampleUsecase = TestUseCaseWithLargeConfig()
        await usecaseStore.set(name: "test", usecase: exampleUsecase)

        let app = try await buildApplication(usecaseStore: usecaseStore)
        let user = UserIdentifier()

        let configRequest = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigRequest.with { configReq in
            configReq.usecases = ["test"]
        }

        let uncompressedConfigSize = try exampleUsecase.randomConfig.serializedData().count
        try await app.test(.live) { client in
            try await client.execute(
                uri: "/config",
                userIdentifier: user,
                message: configRequest,
                acceptCompression: true)
            { response in
                XCTAssertEqual(response.status, .ok)
                XCTAssertEqual(response.headers[.contentEncoding], "gzip")
                XCTAssertEqual(response.headers[.transferEncoding], "chunked")
                var compressedBody = response.body
                XCTAssertLessThan(compressedBody.readableBytes, uncompressedConfigSize)
                let uncompressed = try compressedBody.decompress(with: .gzip())
                let configResponse =
                    try Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigResponse(
                        serializedBytes: Array(buffer: uncompressed))
                try XCTAssertEqual(configResponse.configs["test"], exampleUsecase.config())
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
            let context: Context<Scheme> = try .init(encryptionParameters: .init(from: .n_4096_logq_27_28_28_logt_4))

            // MARK: get configuration

            var config = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRConfig()
            var evaluationKeyConfig = Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig()

            try await client.execute(
                uri: "/config",
                userIdentifier: user,
                message: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigRequest())
            { response in
                XCTAssertEqual(response.status, .ok)
                let configResponse = try response
                    .message(as: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_ConfigResponse.self)

                config = try XCTUnwrap(configResponse.configs["test"]).pirConfig
                evaluationKeyConfig = configResponse.keyInfo[0].keyConfig
            }

            let shardConfig = config.shardConfigs[0]
            let keywordConfig: KeywordPirConfig = try .init(
                dimensionCount: shardConfig.dimensions.count,
                cuckooTableConfig: CuckooTableConfig
                    .defaultKeywordPir(maxSerializedBucketSize: context.bytesPerPlaintext),
                unevenDimensions: false, keyCompression: .noCompression)
            let pirParameter = shardConfig.native(
                batchSize: Int(config.batchSize),
                evaluationKeyConfig: evaluationKeyConfig.native())
            let keywordPirClient: KeywordPirClient<MulPirClient<Scheme>> = .init(
                keywordParameter: keywordConfig.parameter,
                pirParameter: pirParameter,
                context: context)

            // MARK: upload evaluation key

            let secretKey = try Scheme.generateSecretKey(context: context)
            let evaluationKey = try keywordPirClient.generateEvaluationKey(using: secretKey)

            let serializedEvalKey = evaluationKey.serialize().proto()
            let evalKeyMetadata = try Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKeyMetadata
                .with { metadata in
                    metadata.timestamp = UInt64(Date.now.timeIntervalSince1970)
                    metadata.identifier = try evaluationKeyConfig.sha256()
                }
            let evalKey = Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKey.with { evalKey in
                evalKey.metadata = evalKeyMetadata
                evalKey.evaluationKey = serializedEvalKey
            }
            let evaluationKeys = Apple_SwiftHomomorphicEncryption_Api_Shared_V1_EvaluationKeys.with { evalKeys in
                evalKeys.keys = [evalKey]
            }

            try await client.execute(uri: "/key", userIdentifier: user, message: evaluationKeys) { response in
                XCTAssertEqual(response.status, .ok)
            }

            // MARK: query

            let queryKeyword = [UInt8]("23".utf8)

            let query = try keywordPirClient.generateQuery(at: queryKeyword, using: secretKey)

            let pirRequest = try Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRRequest.with { pirRequest in
                pirRequest.shardIndex = 0
                pirRequest.query = try query.proto()
                pirRequest.evaluationKeyMetadata = evalKeyMetadata
                // TODO: fill other fields?
            }
            let request = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Request.with { request in
                request.usecase = "test"
                request.pirRequest = pirRequest
            }
            let requests = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Requests.with { requests in
                requests.requests = [request]
            }

            var pirResponse = Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRResponse()
            try await client
                .execute(uri: "/queries", userIdentifier: user, message: requests) { response in
                    XCTAssertEqual(response.status, .ok)
                    let responses = try response.message(as: Apple_SwiftHomomorphicEncryption_Api_Pir_V1_Responses.self)
                    pirResponse = responses.responses[0].pirResponse
                }

            // MARK: decrypt response

            let response = try pirResponse.native(context: context)
            let result = try keywordPirClient.decrypt(response: response, at: queryKeyword, using: secretKey)

            XCTAssertEqual(result, queryKeyword)
        }
    }
}
