// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import HomomorphicEncryption
import PrivateInformationRetrieval

actor UsecaseStore {
    var store: [String: Usecase]

    var allUsecaseNames: [String] {
        .init(store.keys)
    }

    init() {
        self.store = [:]
    }

    func set(name: String, usecase: Usecase?) {
        store[name] = usecase
    }

    func get(name: String) -> Usecase? {
        store[name]
    }

    func get(names: [String]) -> [String: Usecase] {
        .init(uniqueKeysWithValues: names.compactMap { name in
            guard let usecase = store[name] else {
                return nil
            }
            return (name, usecase)
        })
    }
}
