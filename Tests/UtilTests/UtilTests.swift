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

import Util
import XCTest

class UtilTests: XCTestCase {
    func testOsVersion() throws {
        let os18 = OsVersion(major: 18)
        let os18_0_1 = OsVersion(major: 18, patch: 1)
        let os18_1 = OsVersion(major: 18, minor: 1)
        let os19 = OsVersion(major: 19, minor: 0)

        XCTAssertLessThan(os18, os18_0_1)
        XCTAssertLessThan(os18_0_1, os18_1)
        XCTAssertLessThan(os18, os18_1)
        XCTAssertLessThan(os18, os19)

        XCTAssertEqual(OsVersion(from: "18"), os18)
        XCTAssertEqual(OsVersion(from: "18.0"), os18)
        XCTAssertEqual(OsVersion(from: "18.0.0"), os18)

        XCTAssertEqual(OsVersion(from: "18.1"), os18_1)
        XCTAssertEqual(OsVersion(from: "18.1.0"), os18_1)

        XCTAssertNil(OsVersion(from: "abc"))
        XCTAssertNil(OsVersion(from: "-1"))
        XCTAssertNil(OsVersion(from: "1.2.3.4"))
        XCTAssertNil(OsVersion(from: "1.2.3xyz"))
    }

    func testExampleUserAgent() throws {
        func runTest(platform: Platform) {
            let parsed = Platform(userAgent: platform.exampleUserAgent)
            XCTAssertEqual(parsed, platform)
        }

        runTest(platform: .macOS15)
        runTest(platform: .macOS15_2)
        runTest(platform: .iOS18)
        runTest(platform: .iOS18_2)
    }
}
