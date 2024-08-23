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

/// A protocol for storing nonces to prevent double spending of tokens.
public protocol NonceStoring: Sendable {
    /// Check if a nonce exists.
    /// - Parameter nonce: The nonce to check if it has been used already.
    /// - Returns: True, if the nonce has been inserted to this store.
    func contains(nonce: [UInt8]) async throws -> Bool

    /// Insert a nonce to the store.
    /// - Parameter nonce: The nonce that was used.
    func store(nonce: [UInt8]) async throws
}

/// In memory nonce store that just adds used nonces to a set.
///
/// - Warning: The in memory set of used nonces will keep growing, because there is no garbage collection of old nonces.
public actor InMemoryNonceStore: NonceStoring {
    private var nonces: Set<[UInt8]>

    public init() {
        self.nonces = []
    }

    public func contains(nonce: [UInt8]) async throws -> Bool {
        nonces.contains(nonce)
    }

    public func store(nonce: [UInt8]) async throws {
        nonces.insert(nonce)
    }
}
