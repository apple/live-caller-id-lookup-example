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
import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf

extension KeywordDatabaseShard {
    func save(to path: String) throws {
        try rows.proto().save(to: path)
    }
}

enum ShardingOption: String, CaseIterable, ExpressibleByArgument {
    case entryCountPerShard
    case shardCount
}

struct ShardingArguments: ParsableArguments {
    @Option var sharding: ShardingOption
    @Option var shardingCount: Int
}

extension Sharding {
    init?(from arguments: ShardingArguments) {
        switch arguments.sharding {
        case .entryCountPerShard:
            self.init(entryCountPerShard: arguments.shardingCount)
        case .shardCount:
            self.init(shardCount: arguments.shardingCount)
        }
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

    @Option(help: "path to output PIR database file. Must contain 'SHARD_ID' and have extension '.txtpb' or '.binpb'")
    var outputDatabase: String

    @OptionGroup var sharding: ShardingArguments

    func validate() throws {
        try inputDatabase.validateProtoFilename(descriptor: "inputDatabase")
        try outputDatabase.validateProtoFilename(descriptor: "outputDatabase")
        guard outputDatabase.contains("SHARD_ID") else {
            throw ValidationError("'outputDatabase' must contain 'SHARD_ID', found \(outputDatabase)")
        }
        guard Sharding(from: sharding) != nil else {
            throw ValidationError("Invalid sharding \(sharding)")
        }
    }

    mutating func run() throws {
        guard let sharding = Sharding(from: sharding) else {
            throw ValidationError("Invalid sharding \(sharding)")
        }
        let database: [KeywordValuePair] =
            try Apple_SwiftHomomorphicEncryption_Pir_V1_KeywordDatabase(from: inputDatabase).native()
        let sharded = try KeywordDatabase(rows: database, sharding: sharding)
        for (shardID, shard) in sharded.shards {
            let outputDatabaseFilename = outputDatabase.replacingOccurrences(
                of: "SHARD_ID",
                with: String(shardID))
            if !shard.isEmpty {
                try shard.save(to: outputDatabaseFilename)
            }
        }
    }
}
