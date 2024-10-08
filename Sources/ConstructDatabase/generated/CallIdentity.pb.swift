// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: CallIdentity.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

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

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

/// Image format.
enum ImageFormat: SwiftProtobuf.Enum, Swift.CaseIterable {
  typealias RawValue = Int

  /// Unspecified format.
  case unspecified // = 0

  /// High Efficiency Image File Format (HEIF / HEIC).
  case heic // = 1
  case UNRECOGNIZED(Int)

  init() {
    self = .unspecified
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unspecified
    case 1: self = .heic
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .unspecified: return 0
    case .heic: return 1
    case .UNRECOGNIZED(let i): return i
    }
  }

  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static let allCases: [ImageFormat] = [
    .unspecified,
    .heic,
  ]

}

/// Identity Category.
///
/// The system might show identity information differently based on the category.
enum IdentityCategory: SwiftProtobuf.Enum, Swift.CaseIterable {
  typealias RawValue = Int

  /// Unspecified category.
  case unspecified // = 0

  /// Person category.
  case person // = 1

  /// Business category.
  case business // = 2
  case UNRECOGNIZED(Int)

  init() {
    self = .unspecified
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .unspecified
    case 1: self = .person
    case 2: self = .business
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .unspecified: return 0
    case .person: return 1
    case .business: return 2
    case .UNRECOGNIZED(let i): return i
    }
  }

  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static let allCases: [IdentityCategory] = [
    .unspecified,
    .person,
    .business,
  ]

}

/// Icon
struct Icon: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Image format for the icon
  var format: ImageFormat = .unspecified

  /// Encoded image in the specified format.
  var image: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

/// Caller Identity
struct CallIdentity: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// Identity information.
  var name: String = String()

  /// Icon to be displayed with the identity.
  var icon: Icon {
    get {return _icon ?? Icon()}
    set {_icon = newValue}
  }
  /// Returns true if `icon` has been explicitly set.
  var hasIcon: Bool {return self._icon != nil}
  /// Clears the value of `icon`. Subsequent reads from it will return its default value.
  mutating func clearIcon() {self._icon = nil}

  /// Cache expiry minutes.
  ///
  /// The system will reuse this response for this many minutes before requesting it again.
  var cacheExpiryMinutes: UInt32 = 0

  /// Identity category.
  var category: IdentityCategory = .unspecified

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _icon: Icon? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension ImageFormat: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "IMAGE_FORMAT_UNSPECIFIED"),
    1: .same(proto: "IMAGE_FORMAT_HEIC"),
  ]
}

extension IdentityCategory: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "IDENTITY_CATEGORY_UNSPECIFIED"),
    1: .same(proto: "IDENTITY_CATEGORY_PERSON"),
    2: .same(proto: "IDENTITY_CATEGORY_BUSINESS"),
  ]
}

extension Icon: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Icon"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "format"),
    2: .same(proto: "image"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.format) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.image) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.format != .unspecified {
      try visitor.visitSingularEnumField(value: self.format, fieldNumber: 1)
    }
    if !self.image.isEmpty {
      try visitor.visitSingularBytesField(value: self.image, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Icon, rhs: Icon) -> Bool {
    if lhs.format != rhs.format {return false}
    if lhs.image != rhs.image {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension CallIdentity: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "CallIdentity"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "icon"),
    3: .standard(proto: "cache_expiry_minutes"),
    4: .same(proto: "category"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.name) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._icon) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.cacheExpiryMinutes) }()
      case 4: try { try decoder.decodeSingularEnumField(value: &self.category) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
    }
    try { if let v = self._icon {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    if self.cacheExpiryMinutes != 0 {
      try visitor.visitSingularUInt32Field(value: self.cacheExpiryMinutes, fieldNumber: 3)
    }
    if self.category != .unspecified {
      try visitor.visitSingularEnumField(value: self.category, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: CallIdentity, rhs: CallIdentity) -> Bool {
    if lhs.name != rhs.name {return false}
    if lhs._icon != rhs._icon {return false}
    if lhs.cacheExpiryMinutes != rhs.cacheExpiryMinutes {return false}
    if lhs.category != rhs.category {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
