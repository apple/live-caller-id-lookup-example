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
import HummingbirdCore
import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf

enum LoadingError: Error {
    case invalidParameters(shard: String, got: String, expected: String)
}

extension LoadingError {
    static func invalidParameters<Scheme: HeScheme>(
        shard: String,
        got: EncryptionParameters<Scheme>,
        expected: EncryptionParameters<Scheme>) -> Self
    {
        .invalidParameters(shard: shard, got: got.description, expected: expected.description)
    }
}

struct PirUsecase<PirScheme: IndexPirServer>: Usecase {
    typealias Scheme = PirScheme.Scheme
    let context: Context<Scheme>
    let keywordParams: KeywordPirParameter
    let shards: [KeywordPirServer<PirScheme>]

    init(context: Context<Scheme>, keywordParams: KeywordPirParameter, shards: [KeywordPirServer<PirScheme>]) {
        self.context = context
        self.keywordParams = keywordParams
        self.shards = shards
    }

    init(from fileStem: String, shardCount: Int) throws {
        let parameterPath = "\(fileStem)-0.params.txtpb"
        let params = try Apple_SwiftHomomorphicEncryption_Pir_V1_PirParameters(from: parameterPath)
        let encryptionParams: EncryptionParameters<Scheme> = try params.encryptionParameters.native()
        let context: Context<Scheme> = try Context(parameter: encryptionParams)
        self.context = context
        self.keywordParams = params.keywordPirParams.native()
        self.shards = try (0..<shardCount).map { shardIndex in
            let parameterPath = "\(fileStem)-\(shardIndex).params.txtpb"
            let databasePath = "\(fileStem)-\(shardIndex).bin"
            let pirParams = try Apple_SwiftHomomorphicEncryption_Pir_V1_PirParameters(from: parameterPath)
            let encryptionParams: EncryptionParameters<Scheme> = try pirParams.encryptionParameters.native()
            guard encryptionParams == context.parameter else {
                throw LoadingError.invalidParameters(
                    shard: parameterPath,
                    got: encryptionParams,
                    expected: context.parameter)
            }

            let database = try ProcessedDatabase(from: databasePath, context: context)
            let processed = ProcessedDatabaseWithParameters(
                database: database,
                pirParameter: pirParams.native(),
                keywordPirParameter: pirParams.keywordPirParams.native())
            return try KeywordPirServer(context: context, processed: processed)
        }
    }

    @_specialize(where PirScheme == MulPirServer<Bfv<UInt32>>)
    @_specialize(where PirScheme == MulPirServer<Bfv<UInt64>>)
    func process(
        request: Apple_SwiftHomomorphicEncryption_Api_V1_Request,
        evaluationKey: Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey) async throws
        -> Apple_SwiftHomomorphicEncryption_Api_V1_Response
    {
        let pirRequest = request.pirRequest
        guard !pirRequest.hasShardID else {
            throw HTTPError(.notImplemented, message: "overloading shard index with ShardID is not supported")
        }
        let shard = shards[Int(pirRequest.shardIndex)]
        let query: KeywordPirServer<PirScheme>.Query = try pirRequest.query.native(context: context)
        let evaluationKey: EvaluationKey<Scheme> = try evaluationKey.evaluationKey.native(context: context)
        let response = try shard.computeResponse(to: query, using: evaluationKey)
        return Apple_SwiftHomomorphicEncryption_Api_V1_Response.with { apiResponse in
            apiResponse.pirResponse = response.proto()
        }
    }

    func config() throws -> Apple_SwiftHomomorphicEncryption_Api_V1_Config {
        var pirConfig = Apple_SwiftHomomorphicEncryption_Api_V1_PIRConfig()
        pirConfig.encryptionParameters = try context.parameter.proto()
        pirConfig.shardConfigs = shards.map { shard in
            shard.indexPirParameter.proto()
        }
        pirConfig.keywordPirParams = keywordParams.proto()
        pirConfig.algorithm = .mulPir
        pirConfig.batchSize = UInt64(shards.first?.indexPirParameter.batchSize ?? 1)
        pirConfig.evaluationKeyConfigHash = try evaluationKeyConfig().sha256()
        return Apple_SwiftHomomorphicEncryption_Api_V1_Config.with { $0.pirConfig = pirConfig }
    }

    func evaluationKeyConfig() throws -> Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig {
        try shards.map(\.evaluationKeyConfiguration).union().proto(parameter: context.parameter)
    }
}
