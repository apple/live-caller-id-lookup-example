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
import PIRServiceTesting
import PrivateInformationRetrieval
import Util
import XCTest

class PIRServiceTests: XCTestCase {
    func testRequest() async throws {
        let usecaseStore = UsecaseStore()
        try await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        try await app.test(.live) { client in
            var pirClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client)
            let result = try await pirClient.request(keyword: "23")
            XCTAssertEqual(result, "23")
        }
    }

    func testRequestWithPrivacyPass() async throws {
        let usecaseStore = UsecaseStore()
        try await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
        let userAuthenticator = UserAuthenticator()
        await userAuthenticator.add(token: "ABCD", tier: .tier1)
        let privacyPassState = try PrivacyPassState(userAuthenticator: userAuthenticator)
        let app = try await buildApplication(usecaseStore: usecaseStore, privacyPassState: privacyPassState)
        try await app.test(.live) { client in
            var pirClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client, userToken: "ABCD")
            let result = try await pirClient.request(keyword: "23")
            XCTAssertEqual(result, "23")
        }
    }

    func testRoutingToDifferentVersion() async throws {
        let usecaseStore = UsecaseStore()
        // make sure that the configs for these two are different
        XCTAssertNotEqual(try ExampleUsecase.ten.config(), try ExampleUsecase.hundred.config())
        try await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        try await app.test(.live) { client in
            // make a request
            var clientWithOldConfig = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client)
            var result = try await clientWithOldConfig.request(keyword: "23")
            XCTAssertEqual(result, "23")

            // update the usecase to only have 10 keywords
            try await usecaseStore.set(name: "test", usecase: ExampleUsecase.ten)

            // new client will not get a result for keyword "23"
            var newClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client)
            result = try await newClient.request(keyword: "23")
            XCTAssertNil(result)

            // Request with the old configuration is correctly routed to the previous version.
            result = try await clientWithOldConfig.request(keyword: "23")
            XCTAssertEqual(result, "23")

            // update the usecase again, this time dropping the previous version.
            try await usecaseStore.set(name: "test", usecase: ExampleUsecase.ten, versionCount: 1)

            // request with the old configuration now throws an error
            do {
                _ = try await clientWithOldConfig.request(keyword: "1")
                XCTFail("The previous line should throw!")
            } catch {}
        }
    }

    func testAddingAndRemovingUserTokens() async throws {
        let usecaseStore = UsecaseStore()
        try await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
        let userAuthenticator = UserAuthenticator()
        let privacyPassState = try PrivacyPassState(userAuthenticator: userAuthenticator)
        let app = try await buildApplication(usecaseStore: usecaseStore, privacyPassState: privacyPassState)
        try await app.test(.live) { client in
            var pirClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client, userToken: "ABCD")
            do {
                _ = try await pirClient.request(keyword: "23")
                XCTFail("Previous line should throw!")
            } catch {}

            // after adding the user token, the request should succeed
            await userAuthenticator.add(token: "ABCD", tier: .tier1)

            _ = try await pirClient.request(keyword: "42")

            // remove the user token
            await userAuthenticator.update(allowList: [:])

            // at least one more request should succeed because of cached tokens
            _ = try await pirClient.request(keyword: "42")

            do {
                for _ in 0..<10 {
                    _ = try await pirClient.request(keyword: "this should eventually fail when tokens run out")
                }
                XCTFail("Previous loop should fail")
            } catch {}
        }
    }

    func testRepeatedShardConfigs() async throws {
        let usecaseStore = UsecaseStore()
        try await usecaseStore.set(name: "test", usecase: ExampleUsecase.repeatedShardConfig)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        for platform: Platform in [.macOS15, .macOS15_2, .iOS18, .iOS18_2] {
            try await app.test(.live) { client in
                var pirClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client, platform: platform)
                var queriedShards: Set<Int> = []
                for index in [0, 1] {
                    let keyword = String(index)
                    let result = try await pirClient.request(keyword: keyword)
                    XCTAssertEqual(result, keyword)
                    let shardIndex = try XCTUnwrap(pirClient.configCache["test"]?.config
                        .shardIndex(for: Array(keyword.utf8)))
                    queriedShards.insert(shardIndex)
                }
                XCTAssert(queriedShards.count > 1)
            }
        }
    }

    func testPirConfigExtensions() throws {
        var config = try ExampleUsecase.repeatedShardConfig.config()
        XCTAssertEqual(config.pirConfig.shardConfigs.count, 0)
        XCTAssertEqual(config.pirConfig.pirShardConfigs.repeatedShardConfig.shardCount, 5)
        let shard0Config = config.pirConfig.shardConfig(shardIndex: 0)
        XCTAssertEqual(config.pirConfig.shardCount, 5)

        config.makeCompatible(with: .iOS18)
        XCTAssertEqual(config.pirConfig.shardConfigs.count, 5)
        XCTAssertEqual(config.pirConfig.shardConfigs, Array(repeating: shard0Config, count: 5))
        for shardIndex in 0..<5 {
            XCTAssertEqual(config.pirConfig.shardConfig(shardIndex: shardIndex), shard0Config)
        }
        XCTAssertEqual(config.pirConfig.shardCount, 5)
    }
}

extension PIRClient {
    mutating func request(keyword: String) async throws -> String? {
        let response = try await request(keywords: [.init(keyword.utf8)], usecase: "test")
        XCTAssertEqual(response.count, 1)
        return response[0].map { value in
            String(data: Data(value), encoding: .utf8) ?? "<\(value.count) bytes of binary response>"
        }
    }
}
