// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import ArgumentParser
import Foundation
import HomomorphicEncryption
import HomomorphicEncryptionProtobuf
import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf

extension KeywordDatabase {
    init(from path: String, sharding: Sharding) throws {
        let database = try Apple_SwiftHomomorphicEncryption_Pir_V1_KeywordDatabase(from: path)
        try self.init(rows: database.native(), sharding: sharding)
    }
}

extension PredefinedRlweParameters: @retroactive ExpressibleByArgument {}
extension PirAlgorithm: @retroactive ExpressibleByArgument {}

enum ShardingOption: String, CaseIterable, ExpressibleByArgument {
    case entryCountPerShard
    case shardCount
}

struct ShardingArguments: ParsableArguments {
    @Option var sharding: ShardingOption = .shardCount
    // No good default for both `shardCount` and `entryCountPerShard`
    @Option var shardingCount: Int?
}

extension Sharding {
    init?(from arguments: ShardingArguments) {
        switch arguments.sharding {
        case .entryCountPerShard:
            guard let shardingCount = arguments.shardingCount else {
                return nil
            }
            self.init(entryCountPerShard: shardingCount)
        case .shardCount:
            self.init(shardCount: arguments.shardingCount ?? 1)
        }
    }
}

enum TableSizeOption: String, CaseIterable, ExpressibleByArgument {
    case allowExpansion
    case fixedSize
}

struct CuckooTableArguments: ParsableArguments {
    @Option var hashFunctionCount: Int = 2
    @Option var maxEvictionCount: Int = 100
    @Option var bucketCount: TableSizeOption = .allowExpansion

    @Option(help: "Cuckoo table expansion factor. Requires 'bucket-count = allowExpansion'")
    var tableSizeExpansionFactor: Double = 1.1

    @Option(help: "Cuckoo table target load factor. Requires 'bucket-count = allowExpansion'")
    var tableSizeTargetLoadFactor: Double = 0.9

    @Option(help: "Cuckoo table maximum size in bytes of a serialized bucket")
    var tableSizeMaxSerializedBucketSize: Int?

    @Option(help: "Cuckoo table number of buckets. Requires 'bucket-count = fixedSize'")
    var tableSizeBucketCount: Int?

    var resolvedBucketCount: CuckooTableConfig.BucketCountConfig?

    mutating func validate() throws {
        switch bucketCount {
        case TableSizeOption.allowExpansion:
            resolvedBucketCount = CuckooTableConfig.BucketCountConfig.allowExpansion(
                expansionFactor: tableSizeExpansionFactor,
                targetLoadFactor: tableSizeTargetLoadFactor)
        case TableSizeOption.fixedSize:
            guard let tableSizeBucketCount else {
                throw ValidationError("tableSizeBucketCount must be set for fixedSize cuckoo table")
            }
            resolvedBucketCount = CuckooTableConfig.BucketCountConfig.fixedSize(
                bucketCount: tableSizeBucketCount)
        }
    }
}

extension CuckooTableConfig {
    init(from arguments: CuckooTableArguments) throws {
        guard let tableSizeMaxSerializedBucketSize = arguments.tableSizeMaxSerializedBucketSize
        else {
            throw ValidationError("tableSizeMaxSerializedBucketSize missing")
        }
        guard let bucketCount = arguments.resolvedBucketCount else {
            throw ValidationError("Failed to resolve bucket count")
        }
        try self.init(hashFunctionCount: arguments.hashFunctionCount, maxEvictionCount: arguments.maxEvictionCount,
                      maxSerializedBucketSize: tableSizeMaxSerializedBucketSize,
                      bucketCount: bucketCount)
    }
}

extension String {
    func validateProtoFilename(descriptor: String) throws {
        guard contains("txtpb") || contains("binpb") else {
            throw ValidationError("'\(descriptor)' must contain have extension '.txtpb' or '.binpb', found \(self)")
        }
    }
}

@main
struct ProcessCommand: ParsableCommand {
    @Option(help: "path to input PIR database file. Must have extension '.txtpb' or '.binpb'")
    var inputDatabase: String

    @Option(help: "path to output PIR parameters file. Must contain 'SHARD_ID' unless sharding is shardCount(1).")
    var outputPirParameters: String

    @Option(help: "path to output PIR database file. Must contain 'SHARD_ID' unless sharding is shardCount(1).")
    var outputPirDatabase: String

    @Option(help: "path to output evaluation key configuration file. Must have extension '.txtpb' or '.binpb'")
    var outputEvaluationKeyConfig: String

    @OptionGroup var sharding: ShardingArguments

    @OptionGroup var cuckooTable: CuckooTableArguments

    @Option var rlweParameters: PredefinedRlweParameters

    @Option var algorithm: PirAlgorithm = .mulPir

    @Flag(inversion: .prefixedNo)
    var validatePirCall = true

    mutating func validate() throws {
        try inputDatabase.validateProtoFilename(descriptor: "inputDatabase")
        try outputPirParameters.validateProtoFilename(descriptor: "outputPirParameters")
        try outputEvaluationKeyConfig.validateProtoFilename(descriptor: "outputEvaluationKeyConfig")

        guard let sharding = Sharding(from: sharding) else {
            throw ValidationError("Invalid sharding \(sharding)")
        }
        guard sharding == Sharding.shardCount(1) || outputPirParameters.contains("SHARD_ID") else {
            throw ValidationError("'outputPirParameters' must contain 'SHARD_ID', found \(outputPirParameters)")
        }
        guard sharding == Sharding.shardCount(1) || outputPirDatabase.contains("SHARD_ID") else {
            throw ValidationError("'outputPirDatabase' must contain 'SHARD_ID', found \(outputPirDatabase)")
        }
        guard algorithm == .mulPir else {
            throw ValidationError("'algorithm' must be 'mulPir', found \(algorithm)")
        }
    }

    @inlinable
    mutating func process(_: (some HeScheme).Type) throws {
        guard let sharding = Sharding(from: sharding) else {
            throw ValidationError("Invalid sharding \(sharding)")
        }
        let database: [KeywordValuePair] =
            try Apple_SwiftHomomorphicEncryption_Pir_V1_KeywordDatabase(from: inputDatabase).native()
        if cuckooTable.tableSizeMaxSerializedBucketSize == nil {
            let maxValueSize = database.map { row in row.value.count }.max() ?? 0
            let bytesPerPlaintext = try EncryptionParameters<Bfv<UInt64>>(from: rlweParameters).bytesPerPlaintext
            let singleBucketSize = HashBucket.serializedSize(singleValueSize: maxValueSize)
            cuckooTable.tableSizeMaxSerializedBucketSize = if singleBucketSize >= bytesPerPlaintext / 2 {
                singleBucketSize.nextMultiple(of: bytesPerPlaintext)
            } else {
                bytesPerPlaintext / 2
            }
        }
        let cuckooTableConfig = try CuckooTableConfig(from: cuckooTable)
        let keywordConfig = KeywordPirConfig(dimensionCount: 2,
                                             cuckooTableConfig: cuckooTableConfig,
                                             unevenDimensions: true)
        let keywordPirParams = keywordConfig.parameter.proto()

        let databaseConfig = KeywordDatabaseConfig(
            sharding: sharding,
            keywordPirConfig: keywordConfig)

        let processArgs = ProcessKeywordDatabase.Arguments(databaseConfig: databaseConfig,
                                                           rlweParameters: rlweParameters,
                                                           algorithm: algorithm,
                                                           validate: validatePirCall)

        let processed: ProcessKeywordDatabase.Processed<Bfv<UInt64>> = try ProcessKeywordDatabase
            .process(rows: database, with: processArgs)

        let evaluationKeyConfig = try processed.evaluationKeyConfiguration
            .proto(parameter: EncryptionParameters<Bfv<UInt64>>(from: rlweParameters))
        try evaluationKeyConfig.save(to: outputEvaluationKeyConfig)

        for (shardID, shard) in processed.shards {
            let shardConfig = shard.pirParameter.proto(shardID: shardID)
            let outputDatabaseFilename = outputPirDatabase.replacingOccurrences(
                of: "SHARD_ID",
                with: String(shardID))
            try shard.database.save(to: outputDatabaseFilename)

            let outputParamtersFilename = outputPirParameters.replacingOccurrences(
                of: "SHARD_ID",
                with: String(shardID))

            var pirParameters = Apple_SwiftHomomorphicEncryption_Pir_V1_PirParameters()
            pirParameters.encryptionParameters = try EncryptionParameters<Bfv<UInt64>>(from: rlweParameters).proto()
            pirParameters.numEntries = shardConfig.numEntries
            pirParameters.entrySize = shardConfig.entrySize
            pirParameters.dimensions = shardConfig.dimensions
            pirParameters.batchSize = UInt64(shard.pirParameter.batchSize)
            pirParameters.keywordPirParams = keywordPirParams
            pirParameters.evaluationKeyConfig = evaluationKeyConfig

            try pirParameters.save(to: outputParamtersFilename)
        }
    }

    mutating func run() throws {
        if rlweParameters.supportsScalar(UInt32.self) {
            try process(Bfv<UInt32>.self)
        } else {
            try process(Bfv<UInt64>.self)
        }
    }
}
