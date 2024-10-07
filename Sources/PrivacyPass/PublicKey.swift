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

import _CryptoExtras
import Crypto
import Foundation
import SwiftASN1

/// Public key.
public struct PublicKey: Sendable {
    private static var rsassaPSSParams: RSASSAPSSParams {
        // swiftlint:disable:next force_try
        try! RSASSAPSSParams(hashAlgorithm: .init(algorithm: .HashAlgorithmIdentifier.sha384),
                             maskGenAlgorithm: .init(
                                 algorithm: .MaskGenAlgorithmIdentifier.mgf1,
                                 parameters: ASN1Any(
                                     erasing: AlgorithmIdentifier(algorithm: .HashAlgorithmIdentifier
                                         .sha384))),
                             saltLength: [UInt8(PrivacyPass.TokenTypeBlindRSASaltLength)], trailerField: [1][...])
    }

    let backing: BackingPublicKey
    /// Token key identifier.
    ///
    /// SHA256 of the ``spki()``.
    /// - seealso: [RFC 9578: Issuer Configuration](https://www.rfc-editor.org/rfc/rfc9578#name-issuer-configuration-2)
    public let tokenKeyId: [UInt8]
    /// Truncated token key identifier.
    ///
    /// The last byte of token key identifier.
    public var truncatedTokenKeyId: UInt8 {
        // safe to unwrap, because tokenKeyId is never empty
        // swiftlint:disable:next force_unwrapping
        tokenKeyId.last!
    }

    init(publicKey: BackingPublicKey) {
        self.backing = publicKey
        // this should not throw
        // swiftlint:disable:next force_try
        self.tokenKeyId = try! Self.tokenKeyId(backing: publicKey)
    }

    /// Load a public key from a DER encoded `SubjectPublicKeyInfo` (SPKI) object.
    /// - Parameter derRepresentation: DER enconding of SPKI object.
    /// - seealso: [RFC 9578: Issuer Configuration](https://www.rfc-editor.org/rfc/rfc9578#name-issuer-configuration-2)
    public init(fromSPKI derRepresentation: [UInt8]) throws {
        let rootNode = try DER.parse(derRepresentation)
        var spki = try PrivacyPass.SubjectPublicKeyInfo(derEncoded: rootNode)

        // verify that SPKI has the right parameters set
        guard spki.algorithmIdentifier.algorithm == .AlgorithmIdentifier.rsaPSS,
              let parameters = spki.algorithmIdentifier.parameters,
              let rsassaPSSParams = try? RSASSAPSSParams(asn1Any: parameters),
              rsassaPSSParams == Self.rsassaPSSParams
        else {
            throw PrivacyPassError(code: .invalidSPKIFormat)
        }

        // overwrite algorithmIdentifier such the Crypto can recognize the format
        spki.algorithmIdentifier = AlgorithmIdentifier(
            algorithm: ASN1ObjectIdentifier.AlgorithmIdentifier.rsaEncryption,
            explicitlyEncodeNil: true)
        var serializer = DER.Serializer()
        try serializer.serialize(spki)
        let backing = try BackingPublicKey(
            derRepresentation: serializer.serializedBytes,
            parameters: .RSABSSA_SHA384_PSS_Deterministic)
        self.init(publicKey: backing)
    }

    private static func spki(backing: BackingPublicKey) throws -> [UInt8] {
        let bytes = Array(backing.derRepresentation)
        let rootNode = try DER.parse(bytes)
        var spki = try PrivacyPass.SubjectPublicKeyInfo(derEncoded: rootNode)
        // overwrite algorithmIdentifier with the required parameters
        // swiftlint:disable:next force_try
        spki.algorithmIdentifier = try! .init(
            algorithm: .AlgorithmIdentifier.rsaPSS,
            parameters: .init(erasing: Self.rsassaPSSParams))
        var serializer = DER.Serializer()
        try serializer.serialize(spki)
        return serializer.serializedBytes
    }

    private static func tokenKeyId(backing: BackingPublicKey) throws -> [UInt8] {
        let spki = try Self.spki(backing: backing)
        let digest = SHA256.hash(data: spki)
        return digest.withUnsafeBytes { digestBuffer in
            Array(digestBuffer)
        }
    }

    /// Convert the key to DER-encoded `SubjectPublicKeyInfo` (SPKI) object.
    /// - Returns: DER-encoded SPKI object.
    /// - seealso: [RFC 9578: Issuer Configuration](https://www.rfc-editor.org/rfc/rfc9578#name-issuer-configuration-2)
    public func spki() throws -> [UInt8] {
        try Self.spki(backing: backing)
    }
}

private struct SubjectPublicKeyInfo: DERImplicitlyTaggable, Equatable {
    static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

    var algorithmIdentifier: AlgorithmIdentifier
    var key: ASN1BitString

    init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        // The SPKI block looks like this:
        //
        // SubjectPublicKeyInfo  ::=  SEQUENCE  {
        //   algorithm         AlgorithmIdentifier,
        //   subjectPublicKey  BIT STRING
        // }
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let algorithmIdentifier = try AlgorithmIdentifier(derEncoded: &nodes)
            let key = try ASN1BitString(derEncoded: &nodes)

            return SubjectPublicKeyInfo(algorithmIdentifier: algorithmIdentifier, key: key)
        }
    }

    private init(algorithmIdentifier: AlgorithmIdentifier, key: ASN1BitString) {
        self.algorithmIdentifier = algorithmIdentifier
        self.key = key
    }

    init(algorithmIdentifier: AlgorithmIdentifier, key: [UInt8]) {
        self.algorithmIdentifier = algorithmIdentifier
        self.key = ASN1BitString(bytes: key[...])
    }

    func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(algorithmIdentifier)
            try coder.serialize(key)
        }
    }
}

private struct AlgorithmIdentifier: DERImplicitlyTaggable, Equatable {
    static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

    static let sha1Identifier = Self(algorithm: .HashAlgorithmIdentifier.sha1)
    static let mgf1SHA1Identifier = Self(
        algorithm: .MaskGenAlgorithmIdentifier.mgf1,
        // swiftlint:disable:next force_try
        parameters: try! ASN1Any(erasing: Self.sha1Identifier))

    var algorithm: ASN1ObjectIdentifier
    var parameters: ASN1Any?
    var explicitlyEncodeNil: Bool

    init(algorithm: ASN1ObjectIdentifier, parameters: ASN1Any? = nil, explicitlyEncodeNil: Bool = false) {
        self.algorithm = algorithm
        self.parameters = parameters
        self.explicitlyEncodeNil = explicitlyEncodeNil
    }

    init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        // The AlgorithmIdentifier block looks like this.
        //
        // AlgorithmIdentifier  ::=  SEQUENCE  {
        //   algorithm   OBJECT IDENTIFIER,
        //   parameters  ANY DEFINED BY algorithm OPTIONAL
        // }
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let algorithmOID = try ASN1ObjectIdentifier(derEncoded: &nodes)
            let parameters = nodes.next().map { ASN1Any(derEncoded: $0) }

            return .init(algorithm: algorithmOID, parameters: parameters)
        }
    }

    func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(algorithm)
            if let parameters {
                try coder.serialize(parameters)
            } else {
                if explicitlyEncodeNil {
                    try coder.serialize(ASN1Null())
                }
            }
        }
    }
}

private struct RSASSAPSSParams: DERImplicitlyTaggable, Equatable {
    static var defaultIdentifier: ASN1Identifier {
        .sequence
    }

    var hashAlgorithm: AlgorithmIdentifier
    var maskGenAlgorithm: AlgorithmIdentifier
    var saltLength: ArraySlice<UInt8>
    var trailerField: ArraySlice<UInt8>

    init(
        hashAlgorithm: AlgorithmIdentifier,
        maskGenAlgorithm: AlgorithmIdentifier,
        saltLength: ArraySlice<UInt8>,
        trailerField: ArraySlice<UInt8>)
    {
        self.hashAlgorithm = hashAlgorithm
        self.maskGenAlgorithm = maskGenAlgorithm
        self.saltLength = saltLength
        self.trailerField = trailerField
    }

    init(derEncoded rootNode: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        // RSASSA-PSS-params  ::=  SEQUENCE  {
        //    hashAlgorithm      [0] HashAlgorithm DEFAULT
        //                              sha1Identifier,
        //    maskGenAlgorithm   [1] MaskGenAlgorithm DEFAULT
        //                              mgf1SHA1Identifier,
        //    saltLength         [2] INTEGER DEFAULT 20,
        //    trailerField       [3] INTEGER DEFAULT 1  }
        self = try DER.sequence(rootNode, identifier: identifier) { nodes in
            let hashAlgorithm = try DER.decodeDefaultExplicitlyTagged(
                &nodes,
                tagNumber: 0,
                tagClass: .contextSpecific,
                defaultValue: AlgorithmIdentifier.sha1Identifier)
            let maskGenAlgorithm = try DER.decodeDefaultExplicitlyTagged(
                &nodes,
                tagNumber: 1,
                tagClass: .contextSpecific,
                defaultValue: AlgorithmIdentifier.mgf1SHA1Identifier)
            let saltLength = try DER.decodeDefaultExplicitlyTagged(
                &nodes,
                tagNumber: 2,
                tagClass: .contextSpecific,
                defaultValue: [20][...])
            let trailerField = try DER.decodeDefaultExplicitlyTagged(
                &nodes,
                tagNumber: 3,
                tagClass: .contextSpecific,
                defaultValue: [1][...])

            return .init(
                hashAlgorithm: hashAlgorithm,
                maskGenAlgorithm: maskGenAlgorithm,
                saltLength: saltLength,
                trailerField: trailerField)
        }
    }

    func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(hashAlgorithm, explicitlyTaggedWithTagNumber: 0, tagClass: .contextSpecific)
            try coder.serialize(maskGenAlgorithm, explicitlyTaggedWithTagNumber: 1, tagClass: .contextSpecific)
            try coder.serialize(saltLength, explicitlyTaggedWithTagNumber: 2, tagClass: .contextSpecific)
        }
    }
}

private extension ASN1ObjectIdentifier {
    enum HashAlgorithmIdentifier {
        static let sha1: ASN1ObjectIdentifier = [1, 3, 14, 3, 2, 26]
        static let sha384: ASN1ObjectIdentifier = [2, 16, 840, 1, 101, 3, 4, 2, 2]
    }

    enum MaskGenAlgorithmIdentifier {
        static let mgf1: ASN1ObjectIdentifier = [1, 2, 840, 113_549, 1, 1, 8]
    }
}
