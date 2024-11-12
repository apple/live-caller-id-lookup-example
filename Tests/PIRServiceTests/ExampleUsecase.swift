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
@testable import PIRService
import PrivateInformationRetrieval

enum ExampleUsecase {
    /// Usecase where there are keys in the range `0..<100` and the values are equal to keys.
    static let hundred: Usecase = // swiftlint:disable:next force_try
        try! buildExampleUsecase()

    private static func buildExampleUsecase() throws -> Usecase {
        typealias ServerType = KeywordPirServer<MulPirServer<Bfv<UInt32>>>
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
}
