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
