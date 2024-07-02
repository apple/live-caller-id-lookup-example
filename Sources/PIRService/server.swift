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

import ArgumentParser
import Foundation
import Hummingbird

struct ServerConfiguration: Codable {
    struct Usecase: Codable {
        let name: String
        let fileStem: String
        let shardCount: Int
    }

    let issuerRequestUri: String
    let users: [UserTier: [String]]
    let usecases: [Usecase]
}

@main
struct ServerCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "PIRService")

    @Option var hostname: String = "127.0.0.1"
    @Option var port: Int = 8080
    @Option var configFile: String?
    @Argument var usecases: [String] = []
    @Flag var test = false

    func run() async throws {
        var privacyPassState: PrivacyPassState<UserAuthenticator>?
        let usecaseStore = UsecaseStore()
        if test {
            try await usecaseStore.set(name: "test", usecase: buildExampleUsecase())
        }

        for name in usecases {
            let usecase = try loadUsecase(from: name, shardCount: 1)
            await usecaseStore.set(name: name, usecase: usecase)
        }

        if let configFile {
            let configURL = URL(fileURLWithPath: configFile)
            let configData = try Data(contentsOf: configURL)
            let config = try JSONDecoder().decode(ServerConfiguration.self, from: configData)

            if !config.users.isEmpty {
                let authenticator = UserAuthenticator()
                for (tier, users) in config.users {
                    for user in users {
                        await authenticator.add(token: user, tier: tier)
                    }
                }
                guard let issuerRequestUri = URL(string: config.issuerRequestUri) else {
                    throw ValidationError("invalid issuerRequestUri: \(config.issuerRequestUri)")
                }
                privacyPassState = try .init(issuerRequestUri: issuerRequestUri, userAuthenticator: authenticator)
            }

            for usecase in config.usecases {
                let loaded = try loadUsecase(from: usecase.fileStem, shardCount: usecase.shardCount)
                await usecaseStore.set(name: usecase.name, usecase: loaded)
            }
        }

        let app = try await buildApplication(
            configuration: .init(address: .hostname(hostname, port: port)),
            usecaseStore: usecaseStore,
            privacyPassState: privacyPassState)
        try await app.runService()
    }
}
