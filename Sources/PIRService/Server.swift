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
import ServiceLifecycle

@main
struct ServerCommand: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "PIRService")

    @Option var hostname: String = "127.0.0.1"
    @Option var port: Int = 8080
    @Argument var configFile: String

    func run() async throws {
        let usecaseStore = UsecaseStore()
        let privacyPassState = try PrivacyPassState(userAuthenticator: UserAuthenticator())

        let app = try await buildApplication(
            configuration: .init(address: .hostname(hostname, port: port)),
            usecaseStore: usecaseStore,
            privacyPassState: privacyPassState)

        let reloadService = ReloadService(
            configFile: URL(fileURLWithPath: configFile),
            usecaseStore: usecaseStore,
            privacyPassState: privacyPassState,
            logger: app.logger)

        try await reloadService.reloadConfiguration()

        let serviceGroup = ServiceGroup(configuration: .init(services: [app, reloadService], logger: app.logger))
        try await serviceGroup.run()
    }
}
