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

import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf

extension Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRConfig {
    var shardCount: Int {
        if let pirShardConfigs = pirShardConfigs.shardConfigs {
            switch pirShardConfigs {
            case let .repeatedShardConfig(repeatedConfig):
                return Int(repeatedConfig.shardCount)
            }
        }
        return shardConfigs.count
    }

    func shardConfig(shardIndex: Int) -> Apple_SwiftHomomorphicEncryption_Api_Pir_V1_PIRShardConfig {
        if let pirShardConfigs = pirShardConfigs.shardConfigs {
            switch pirShardConfigs {
            case let .repeatedShardConfig(repeatedConfig):
                return repeatedConfig.shardConfig
            }
        }
        return shardConfigs[shardIndex]
    }

    func shardindex(for keyword: KeywordValuePair.Keyword) throws -> Int {
        if keywordPirParams.hasShardingFunction {
            switch keywordPirParams.shardingFunction.function {
            case .sha256:
                return keyword.shardIndex(shardCount: shardCount)
            case let .doubleMod(doubleMod):
                let otherShardIndex = keyword.shardIndex(shardCount: Int(doubleMod.otherShardCount))
                return otherShardIndex % shardCount
            default:
                throw PIRClientError
                    .unknownShardingFunction(shardingFunction: keywordPirParams.shardingFunction.textFormatString())
            }
        }

        return keyword.shardIndex(shardCount: shardCount)
    }
}
