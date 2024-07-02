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

import HomomorphicEncryptionProtobuf
import PrivateInformationRetrievalProtobuf

protocol Usecase: Sendable {
    func config() throws -> Apple_SwiftHomomorphicEncryption_Api_V1_Config
    func evaluationKeyConfig() throws -> Apple_SwiftHomomorphicEncryption_V1_EvaluationKeyConfig
    func process(
        request: Apple_SwiftHomomorphicEncryption_Api_V1_Request,
        evaluationKey: Apple_SwiftHomomorphicEncryption_Api_V1_EvaluationKey) async throws
        -> Apple_SwiftHomomorphicEncryption_Api_V1_Response
}
