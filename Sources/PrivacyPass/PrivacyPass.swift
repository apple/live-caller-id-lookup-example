// Copyright 2024 Apple Inc. and the Swift Homomorphic Encryption project authors
//
// This file is part of the Swift Homomorphic Encryption project, located at:
//   https://github.com/apple/swift-homomorphic-encryption
//
// This file is subject to the License in the LICENSE.txt file (located at the
// top level of this project). If you did not receive a copy of the License
// with this file, please refer to the project's LICENSE in the project's
// repository, located at the URL above.

import _CryptoExtras
import Crypto

typealias BackingPrivateKey = _RSA.BlindSigning.PrivateKey<SHA384>
typealias BackingPublicKey = _RSA.BlindSigning.PublicKey<SHA384>

/// Token type for Blind RSA (2048-bit).
///
/// - seealso: [RFC 9578: Privacy Pass Token
/// Types](https://www.rfc-editor.org/rfc/rfc9578#name-privacy-pass-token-types)
public let TokenTypeBlindRSA: UInt16 = 2
let TokenTypeBlindRSAKeySizeInBits: Int = 2048
let TokenTypeBlindRSANK: Int = 256
let TokenTypeBlindRSASaltLength: Int = 48
let TokenTypeBlindRSAParams: _RSA.BlindSigning.Parameters = .RSABSSA_SHA384_PSS_Deterministic
