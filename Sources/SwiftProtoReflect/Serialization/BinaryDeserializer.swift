//
// BinaryDeserializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// BinaryDeserializer.
///
/// Provides functionality for deserializing dynamic Protocol Buffers messages
/// from binary wire format, using integration with Swift Protobuf library
/// to ensure compatibility with Protocol Buffers standard.
public struct BinaryDeserializer {

  // MARK: - Properties

  /// Deserialization options.
  public let options: DeserializationOptions

  // MARK: - Initialization

  /// Creates new BinaryDeserializer instance.
  ///
  /// - Parameter options: Deserialization options.
  public init(options: DeserializationOptions) {
    self.options = options
  }

  /// Creates a BinaryDeserializer with default options and an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(options:)` with an explicit `TypeRegistry` so that
  ///   cross-file message types can be resolved correctly.
  @available(*, deprecated, message: "Use init(options:) with an explicit TypeRegistry")
  public init() {
    self.init(
      options: DeserializationOptions(
        preserveUnknownFields: true,
        strictUTF8Validation: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  // MARK: - Deserialization Methods

  /// Deserializes binary data to dynamic message.
  ///
  /// - Parameters:
  ///   - data: Binary data to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: DeserializationError if deserialization failed.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    var decoder = BinaryDecoder(data: data)
    return try decodeMessage(from: &decoder, using: descriptor)
  }

  // MARK: - Private Methods

  /// Decodes message from binary decoder.
  private func decodeMessage(from decoder: inout BinaryDecoder, using descriptor: MessageDescriptor) throws
    -> DynamicMessage
  {
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)
    var unknownFields = Data()

    while decoder.hasMoreData {
      // Read tag (field number + wire type)
      let tag = try decoder.readVarint()
      let fieldNumber = Int(tag >> 3)
      let wireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let wireType = wireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      if let field = descriptor.field(number: fieldNumber) ?? descriptor.extensions[fieldNumber] {
        try decodeField(field, wireType: wireType, from: &decoder, into: &message, descriptor: descriptor)
      }
      else {
        // Unknown field - preserve for compatibility
        if options.preserveUnknownFields {
          let unknownFieldData = try skipUnknownField(wireType: wireType, from: &decoder)
          var tagBytes = Data()
          var tagVal = tag
          while tagVal >= 0x80 {
            tagBytes.append(UInt8(tagVal & 0x7F | 0x80))
            tagVal >>= 7
          }
          tagBytes.append(UInt8(tagVal & 0x7F))
          unknownFields.append(tagBytes)
          unknownFields.append(unknownFieldData)
        }
        else {
          _ = try skipUnknownField(wireType: wireType, from: &decoder)
        }
      }
    }

    if !unknownFields.isEmpty {
      message.setUnknownFields(unknownFields)
    }

    return message
  }

  /// Decodes single field.
  private func decodeField(
    _ field: FieldDescriptor,
    wireType: WireType,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage,
    descriptor: MessageDescriptor
  ) throws {

    let expectedWireType = getWireType(for: field.type)
    let isPackedRepeated = field.isRepeated && wireType == .lengthDelimited && expectedWireType != .lengthDelimited

    if wireType != expectedWireType && !isPackedRepeated {
      throw DeserializationError.wireTypeMismatch(
        fieldName: field.name,
        expected: expectedWireType,
        actual: wireType
      )
    }

    if field.isMap {
      try decodeMapField(field, from: &decoder, into: &message, descriptor: descriptor)
    }
    else if field.isRepeated {
      if isPackedRepeated {
        try decodePackedRepeatedField(field, from: &decoder, into: &message, descriptor: descriptor)
      }
      else {
        try decodeRepeatedField(field, from: &decoder, into: &message, descriptor: descriptor)
      }
    }
    else {
      try decodeSingleField(field, from: &decoder, into: &message, descriptor: descriptor)
    }
  }

  /// Decodes single field.
  private func decodeSingleField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage,
    descriptor: MessageDescriptor
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder, descriptor: descriptor)
    try message.set(value, forField: field.number)
  }

  /// Decodes repeated field.
  private func decodeRepeatedField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage,
    descriptor: MessageDescriptor
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder, descriptor: descriptor)

    let fieldAccess = FieldAccessor(message)
    var array: [Any] = []

    if fieldAccess.hasValue(field.number) {
      array = fieldAccess.getValue(field.number, as: [Any].self) ?? []
    }

    array.append(value)
    try message.set(array, forField: field.number)
  }

  /// Decodes packed repeated field.
  private func decodePackedRepeatedField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage,
    descriptor: MessageDescriptor
  ) throws {
    let length = try decoder.readVarint()
    let endPosition = decoder.position + Int(length)

    var array: [Any] = []

    while decoder.position < endPosition {
      let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder, descriptor: descriptor)
      array.append(value)
    }

    if decoder.position != endPosition {
      throw DeserializationError.malformedPackedField(fieldName: field.name)
    }

    try message.set(array, forField: field.number)
  }

  /// Decodes map field.
  private func decodeMapField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage,
    descriptor: MessageDescriptor
  ) throws {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw DeserializationError.missingMapEntryInfo(fieldName: field.name)
    }

    let entryLength = try decoder.readVarint()
    let entryEndPosition = decoder.position + Int(entryLength)

    var key: Any?
    var value: Any?

    while decoder.position < entryEndPosition {
      let tag = try decoder.readVarint()
      let entryFieldNumber = Int(tag >> 3)
      let entryWireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let entryWireType = entryWireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      switch entryFieldNumber {
      case 1:
        key = try decodeValue(
          type: mapEntryInfo.keyFieldInfo.type,
          typeName: nil,
          from: &decoder,
          descriptor: descriptor
        )
      case 2:
        value = try decodeValue(
          type: mapEntryInfo.valueFieldInfo.type,
          typeName: mapEntryInfo.valueFieldInfo.typeName,
          from: &decoder,
          descriptor: descriptor
        )
      default:
        // Skip unknown fields in map entry
        _ = try skipUnknownField(wireType: entryWireType, from: &decoder)
      }
    }

    if decoder.position != entryEndPosition {
      throw DeserializationError.malformedMapEntry(fieldName: field.name)
    }

    // Add to existing map or create new one
    let fieldAccess = FieldAccessor(message)
    var map: [AnyHashable: Any] = [:]

    if fieldAccess.hasValue(field.name) {
      map = fieldAccess.getValue(field.name, as: [AnyHashable: Any].self) ?? [:]
    }

    if let key = key as? AnyHashable, let value = value {
      map[key] = value
      try message.set(map, forField: field.number)
    }
  }

  /// Decodes value of specific type.
  private func decodeValue(
    type: FieldType,
    typeName: String?,
    from decoder: inout BinaryDecoder,
    descriptor: MessageDescriptor
  ) throws -> Any {
    switch type {
    case .double:
      return try decoder.readDouble()

    case .float:
      return try decoder.readFloat()

    case .int32:
      let varint = try decoder.readVarint()
      return Int32(truncatingIfNeeded: varint)

    case .int64:
      let varint = try decoder.readVarint()
      return Int64(bitPattern: varint)

    case .uint32:
      let varint = try decoder.readVarint()
      return UInt32(truncatingIfNeeded: varint)

    case .uint64:
      return try decoder.readVarint()

    case .sint32:
      let varint = try decoder.readVarint()
      return BinaryDeserializer.zigzagDecode32(UInt32(truncatingIfNeeded: varint))

    case .sint64:
      let varint = try decoder.readVarint()
      return BinaryDeserializer.zigzagDecode64(varint)

    case .fixed32:
      return try decoder.readFixed32()

    case .fixed64:
      return try decoder.readFixed64()

    case .sfixed32:
      let fixed32 = try decoder.readFixed32()
      return Int32(bitPattern: fixed32)

    case .sfixed64:
      let fixed64 = try decoder.readFixed64()
      return Int64(bitPattern: fixed64)

    case .bool:
      let varint = try decoder.readVarint()
      return varint != 0

    case .string:
      return try decodeString(from: &decoder)

    case .bytes:
      return try decodeLengthDelimitedBytes(from: &decoder)

    case .message:
      guard let typeName = typeName else {
        throw DeserializationError.missingTypeName(fieldType: "message")
      }
      return try decodeMessageField(typeName: typeName, from: &decoder, descriptor: descriptor)

    case .enum:
      let varint = try decoder.readVarint()
      return Int32(truncatingIfNeeded: varint)

    case .group:
      guard let typeName = typeName else {
        throw DeserializationError.missingTypeName(fieldType: "group")
      }
      return try decodeGroupField(typeName: typeName, from: &decoder, descriptor: descriptor)
    }
  }

  /// Reads a length-delimited byte sequence and decodes it as a UTF-8 string.
  private func decodeString(from decoder: inout BinaryDecoder) throws -> String {
    let length = try decoder.readVarint()
    let data = try decoder.readBytes(Int(length))
    guard let string = String(data: data, encoding: .utf8) else {
      throw DeserializationError.invalidUTF8String
    }
    return string
  }

  /// Reads a length-delimited byte sequence and returns it as raw `Data`.
  private func decodeLengthDelimitedBytes(from decoder: inout BinaryDecoder) throws -> Data {
    let length = try decoder.readVarint()
    return try decoder.readBytes(Int(length))
  }

  /// Reads a length-delimited embedded message and decodes it using the resolved descriptor.
  private func decodeMessageField(
    typeName: String,
    from decoder: inout BinaryDecoder,
    descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    let length = try decoder.readVarint()
    let messageData = try decoder.readBytes(Int(length))
    let nestedDescriptor = try resolveMessageDescriptor(typeName: typeName, in: descriptor)
    var nestedDecoder = BinaryDecoder(data: messageData)
    return try decodeMessage(from: &nestedDecoder, using: nestedDescriptor)
  }

  /// Reads a proto2 group field and decodes it using the resolved descriptor.
  private func decodeGroupField(
    typeName: String,
    from decoder: inout BinaryDecoder,
    descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    let groupDescriptor = try resolveMessageDescriptor(typeName: typeName, in: descriptor)
    return try decodeGroupMessage(from: &decoder, using: groupDescriptor)
  }

  /// Resolves a `MessageDescriptor` for `typeName`.
  ///
  /// 1. `options.typeRegistry` by fully-qualified name (primary — correct, strict resolution).
  /// 2. Structural nesting on `descriptor` (deprecated fallback — legacy path).
  private func resolveMessageDescriptor(typeName: String, in descriptor: MessageDescriptor) throws
    -> MessageDescriptor
  {
    let normalizedTypeName = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
    if let desc = options.typeRegistry.findMessage(named: normalizedTypeName) {
      return desc
    }
    // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
    // Users should register all types in TypeRegistry instead of relying on addNestedMessage().
    let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
    if let desc = descriptor.nestedMessage(named: simpleName) {
      return desc
    }
    throw DeserializationError.unsupportedNestedMessage(typeName: typeName)
  }

  /// Decodes a group message, reading fields until endGroup tag.
  private func decodeGroupMessage(
    from decoder: inout BinaryDecoder,
    using descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)

    while decoder.hasMoreData {
      let tag = try decoder.readVarint()
      let fieldNumber = Int(tag >> 3)
      let wireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let wireType = wireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      if wireType == .endGroup {
        return message
      }

      if let field = descriptor.field(number: fieldNumber) {
        try decodeField(field, wireType: wireType, from: &decoder, into: &message, descriptor: descriptor)
      }
      else {
        _ = try skipUnknownField(wireType: wireType, from: &decoder)
      }
    }

    throw DeserializationError.truncatedMessage
  }

  /// Skips unknown field and returns its data.
  private func skipUnknownField(wireType: WireType, from decoder: inout BinaryDecoder) throws -> Data {
    let startPosition = decoder.position

    switch wireType {
    case .varint:
      _ = try decoder.readVarint()

    case .fixed32:
      _ = try decoder.readFixed32()

    case .fixed64:
      _ = try decoder.readFixed64()

    case .lengthDelimited:
      let length = try decoder.readVarint()
      _ = try decoder.readBytes(Int(length))

    case .startGroup:
      try skipGroup(from: &decoder)

    case .endGroup:
      break
    }

    let endPosition = decoder.position
    return decoder.data.subdata(in: startPosition..<endPosition)
  }

  /// Skips an entire group by reading until the matching endGroup tag.
  private func skipGroup(from decoder: inout BinaryDecoder) throws {
    while decoder.hasMoreData {
      let tag = try decoder.readVarint()
      let wireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let wireType = wireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      if wireType == .endGroup {
        return
      }

      _ = try skipUnknownField(wireType: wireType, from: &decoder)
    }

    throw DeserializationError.truncatedMessage
  }

  /// Determines wire type for field.
  private func getWireType(for fieldType: FieldType) -> WireType {
    switch fieldType {
    case .double, .fixed64, .sfixed64:
      return .fixed64
    case .float, .fixed32, .sfixed32:
      return .fixed32
    case .int32, .int64, .uint32, .uint64, .sint32, .sint64, .bool, .enum:
      return .varint
    case .string, .bytes, .message:
      return .lengthDelimited
    case .group:
      return .startGroup  // Deprecated
    }
  }

  // MARK: - ZigZag Decoding

  /// ZigZag decoding for 32-bit signed numbers.
  static func zigzagDecode32(_ value: UInt32) -> Int32 {
    let shifted = value >> 1
    let mask = UInt32(bitPattern: -Int32(value & 1))
    return Int32(bitPattern: shifted ^ mask)
  }

  /// ZigZag decoding for 64-bit signed numbers.
  static func zigzagDecode64(_ value: UInt64) -> Int64 {
    let shifted = value >> 1
    let mask = UInt64(bitPattern: -Int64(value & 1))
    return Int64(bitPattern: shifted ^ mask)
  }
}

// MARK: - Binary Decoder

/// Low-level binary decoder for Protocol Buffers wire format.
private struct BinaryDecoder {
  let data: Data
  var position: Int = 0

  var hasMoreData: Bool {
    return position < data.count
  }

  init(data: Data) {
    self.data = data
  }

  /// Reads varint value.
  mutating func readVarint() throws -> UInt64 {
    var result: UInt64 = 0
    var shift = 0

    while position < data.count && shift < 64 {
      let byte = data[position]
      position += 1

      result |= UInt64(byte & 0x7F) << shift

      if (byte & 0x80) == 0 {
        return result
      }

      shift += 7
    }

    throw DeserializationError.truncatedVarint
  }

  /// Reads 32-bit fixed value.
  mutating func readFixed32() throws -> UInt32 {
    guard position + 4 <= data.count else {
      throw DeserializationError.truncatedMessage
    }

    let result = data.subdata(in: position..<position + 4).withUnsafeBytes { bytes in
      bytes.load(as: UInt32.self)
    }.littleEndian

    position += 4
    return result
  }

  /// Reads 64-bit fixed value.
  mutating func readFixed64() throws -> UInt64 {
    guard position + 8 <= data.count else {
      throw DeserializationError.truncatedMessage
    }

    let result = data.subdata(in: position..<position + 8).withUnsafeBytes { bytes in
      bytes.load(as: UInt64.self)
    }.littleEndian

    position += 8
    return result
  }

  /// Reads float value.
  mutating func readFloat() throws -> Float {
    let bits = try readFixed32()
    return Float(bitPattern: bits)
  }

  /// Reads double value.
  mutating func readDouble() throws -> Double {
    let bits = try readFixed64()
    return Double(bitPattern: bits)
  }

  /// Reads specified number of bytes.
  mutating func readBytes(_ count: Int) throws -> Data {
    guard position + count <= data.count else {
      throw DeserializationError.truncatedMessage
    }

    let result = data.subdata(in: position..<position + count)
    position += count
    return result
  }
}

// MARK: - Deserialization Options

/// Options for deserialization.
public struct DeserializationOptions {
  /// Whether to preserve unknown fields for backward compatibility.
  public let preserveUnknownFields: Bool

  /// Strict UTF-8 string validation.
  public let strictUTF8Validation: Bool

  /// Registry used to resolve message-type fields by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file and sibling-message resolution.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Creates deserialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - preserveUnknownFields: Whether to preserve unknown fields. Defaults to `true`.
  ///   - strictUTF8Validation: Whether to enforce strict UTF-8 string validation. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving message types by fully-qualified name.
  public init(
    preserveUnknownFields: Bool = true,
    strictUTF8Validation: Bool = true,
    typeRegistry: TypeRegistry
  ) {
    self.preserveUnknownFields = preserveUnknownFields
    self.strictUTF8Validation = strictUTF8Validation
    self.typeRegistry = typeRegistry
  }

  /// Creates deserialization options with an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(preserveUnknownFields:strictUTF8Validation:typeRegistry:)` with an
  ///   explicit `TypeRegistry` so that cross-file message types can be resolved correctly.
  @available(
    *,
    deprecated,
    message: "Use init(preserveUnknownFields:strictUTF8Validation:typeRegistry:) with an explicit TypeRegistry"
  )
  public init(
    preserveUnknownFields: Bool = true,
    strictUTF8Validation: Bool = true
  ) {
    self.init(
      preserveUnknownFields: preserveUnknownFields,
      strictUTF8Validation: strictUTF8Validation,
      typeRegistry: TypeRegistry()
    )
  }
}

// MARK: - Deserialization Errors

/// Deserialization errors.
public enum DeserializationError: Error, Equatable {
  case truncatedVarint
  case truncatedMessage
  case invalidWireType(tag: UInt32)
  case wireTypeMismatch(fieldName: String, expected: WireType, actual: WireType)
  case invalidUTF8String
  case malformedPackedField(fieldName: String)
  case malformedMapEntry(fieldName: String)
  case missingMapEntryInfo(fieldName: String)
  case missingTypeName(fieldType: String)
  case unsupportedNestedMessage(typeName: String)
  case unsupportedFieldType(type: String)

  public var description: String {
    switch self {
    case .truncatedVarint:
      return "Truncated varint"
    case .truncatedMessage:
      return "Truncated message"
    case .invalidWireType(let tag):
      return "Invalid wire type in tag: \(tag)"
    case .wireTypeMismatch(let fieldName, let expected, let actual):
      return "Wire type mismatch for field '\(fieldName)': expected \(expected), got \(actual)"
    case .invalidUTF8String:
      return "Invalid UTF-8 string"
    case .malformedPackedField(let fieldName):
      return "Malformed packed field: \(fieldName)"
    case .malformedMapEntry(let fieldName):
      return "Malformed map entry: \(fieldName)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingTypeName(let fieldType):
      return "Missing type name for field type: \(fieldType)"
    case .unsupportedNestedMessage(let typeName):
      return "Unsupported nested message type: \(typeName)"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    }
  }
}
