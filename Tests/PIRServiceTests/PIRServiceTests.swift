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
import XCTest

class PIRServiceTests: XCTestCase {
    func testRequest() async throws {
        let usecaseStore = UsecaseStore()
        await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
        let app = try await buildApplication(usecaseStore: usecaseStore)
        try await app.test(.live) { client in
            var pirClient = PIRClient<MulPirClient<Bfv<UInt32>>>(connection: client)
            let result = try await pirClient.request(keyword: "23")
            XCTAssertEqual(result, "23")
        }
    }

    func testRequestWithPrivacyPass() async throws {
        let usecaseStore = UsecaseStore()
        await usecaseStore.set(name: "test", usecase: ExampleUsecase.hundred)
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
