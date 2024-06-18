// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

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
