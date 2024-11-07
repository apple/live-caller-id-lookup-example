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

/// Type of an operation system.
public struct OsType: Hashable, Sendable {
    enum Internal {
        case iOS
        case macOS
    }

    /// iOS
    public static let iOS: Self = .init(type: .iOS)

    /// macOS
    public static let macOS: Self = .init(type: .macOS)

    let type: Internal
}

/// A version of an operating system.
public struct OsVersion: Equatable, Hashable, Sendable {
    /// Major version.
    public let major: Int
    /// Minor version.
    public let minor: Int
    /// Patch version.
    public let patch: Int

    /// Initializes an `OsVersion`.
    /// - Parameters:
    ///   - major: Major version.
    ///   - minor: Minor version.
    ///   - patch: Patch version.
    public init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Initializes an `OsVersion` from a string.
    /// - Parameter string: Semantic version string. E.g., `MAJOR.MINOR.PATCH`
    public init?(from string: String) {
        let components = string.split(separator: ".")
        guard components.count >= 1, components.count <= 3 else {
            return nil
        }
        guard let major = Int(components[0]), major >= 0 else {
            return nil
        }
        self.major = major

        if components.count > 1 {
            guard let minor = Int(components[1]), minor >= 0 else {
                return nil
            }
            self.minor = minor
        } else {
            self.minor = 0
        }

        if components.count > 2 {
            guard let patch = Int(components[2]), patch >= 0 else {
                return nil
            }
            self.patch = patch
        } else {
            self.patch = 0
        }
    }
}

extension OsVersion: Comparable {
    public static func < (lhs: OsVersion, rhs: OsVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        }
        return false
    }
}
