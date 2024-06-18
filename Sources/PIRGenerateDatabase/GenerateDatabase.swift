// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import ArgumentParser
import Foundation
import HomomorphicEncryption
import PrivateInformationRetrieval
import PrivateInformationRetrievalProtobuf

enum ValueTypeArguments: String, CaseIterable, ExpressibleByArgument {
    case random
    /// Repeats the keyword
    case repeated
}

struct ValueSizeArguments: ExpressibleByArgument {
    var range: Range<Int>

    init?(argument: String) {
        let parsedOpen = argument.split(separator: "..<")
        if parsedOpen.count == 2, let lower = Int(parsedOpen[0]), let upper = Int(parsedOpen[1]), lower < upper,
           lower > 0, upper > 0
        {
            self.range = lower..<upper
        } else {
            let parsedClosed = argument.split(separator: "...")
            if parsedClosed.count == 2, let lower = Int(parsedClosed[0]), let upper = Int(parsedClosed[1]),
               lower <= upper, lower > 0, upper > 0
            {
                self.range = lower..<(upper + 1)
            } else if parsedClosed.count == 1, let size = Int(parsedClosed[0]), size > 0 {
                self.range = size..<(size + 1)
            } else {
                return nil
            }
        }
    }
}

extension [UInt8] {
    @inlinable
    init(randomByteCount: Int) {
        self = .init(repeating: 0, count: randomByteCount)
        var rng = SystemRandomNumberGenerator()
        rng.fill(&self)
    }
}

@main
struct GenerateDatabaseCommand: ParsableCommand {
    @Option(help: "Path to output database. Must end in '.txtpb' or '.binpb'")
    var outputDatabase: String

    @Option(help: "Number of rows in the database")
    var rowCount: Int

    @Option(help: "Number of bytes in each row. Must be of the form 'x', 'x..<y', or 'x...y'")
    var valueSize: ValueSizeArguments

    @Option var valueType: ValueTypeArguments

    mutating func run() throws {
        let databaseRows = (0..<rowCount)
            .map { rowIndex in
                let keyword = [UInt8](String(rowIndex).utf8)
                guard let valueSize = valueSize.range.randomElement() else {
                    preconditionFailure("Could not sample valueSize from range \(valueSize.range)")
                }

                let value: [UInt8]
                switch valueType {
                case .random:
                    value = [UInt8](randomByteCount: valueSize)
                case .repeated:
                    let repeatCount = valueSize.dividingCeil(keyword.count)
                    value = Array([[UInt8]](repeating: keyword, count: repeatCount).flatMap { $0 }.prefix(valueSize))
                }
                return KeywordValuePair(keyword: keyword, value: value)
            }
        try databaseRows.proto().save(to: outputDatabase)
    }
}
