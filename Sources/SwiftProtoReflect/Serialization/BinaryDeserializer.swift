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
  public init(options: DeserializationOptions = DeserializationOptions()) {
    self.options = options
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

      // Find field by number
      if let field = descriptor.field(number: fieldNumber) {
        try decodeField(field, wireType: wireType, from: &decoder, into: &message)
      }
      else {
        // Unknown field - preserve for compatibility
        if options.preserveUnknownFields {
          let unknownFieldData = try skipUnknownField(wireType: wireType, from: &decoder)
          unknownFields.append(Data([UInt8(tag)]))
          unknownFields.append(unknownFieldData)
        }
        else {
          _ = try skipUnknownField(wireType: wireType, from: &decoder)
        }
      }
    }

    return message
  }

  /// Decodes single field.
  private func decodeField(
    _ field: FieldDescriptor,
    wireType: WireType,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {

    // Check wire type compatibility with field type
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
      try decodeMapField(field, from: &decoder, into: &message)
    }
    else if field.isRepeated {
      if isPackedRepeated {
        try decodePackedRepeatedField(field, from: &decoder, into: &message)
      }
      else {
        try decodeRepeatedField(field, from: &decoder, into: &message)
      }
    }
    else {
      try decodeSingleField(field, from: &decoder, into: &message)
    }
  }

  /// Decodes single field.
  private func decodeSingleField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder)
    try message.set(value, forField: field.name)
  }

  /// Decodes repeated field.
  private func decodeRepeatedField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder)

    // Get existing array or create new one
    let fieldAccess = FieldAccessor(message)
    var array: [Any] = []

    if fieldAccess.hasValue(field.name) {
      array = fieldAccess.getValue(field.name, as: [Any].self) ?? []
    }

    array.append(value)
    try message.set(array, forField: field.name)
  }

  /// Decodes packed repeated field.
  private func decodePackedRepeatedField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    let length = try decoder.readVarint()
    let endPosition = decoder.position + Int(length)

    var array: [Any] = []

    while decoder.position < endPosition {
      let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder)
      array.append(value)
    }

    if decoder.position != endPosition {
      throw DeserializationError.malformedPackedField(fieldName: field.name)
    }

    try message.set(array, forField: field.name)
  }

  /// Decodes map field.
  private func decodeMapField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw DeserializationError.missingMapEntryInfo(fieldName: field.name)
    }

    let entryLength = try decoder.readVarint()
    let entryEndPosition = decoder.position + Int(entryLength)

    var key: Any?
    var value: Any?

    // Read entry as regular message
    while decoder.position < entryEndPosition {
      let tag = try decoder.readVarint()
      let entryFieldNumber = Int(tag >> 3)
      let entryWireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let entryWireType = entryWireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      switch entryFieldNumber {
      case 1:  // key
        key = try decodeValue(type: mapEntryInfo.keyFieldInfo.type, typeName: nil, from: &decoder)
      case 2:  // value
        value = try decodeValue(
          type: mapEntryInfo.valueFieldInfo.type,
          typeName: mapEntryInfo.valueFieldInfo.typeName,
          from: &decoder
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
      try message.set(map, forField: field.name)
    }
  }

  /// Decodes value of specific type.
  private func decodeValue(type: FieldType, typeName: String?, from decoder: inout BinaryDecoder) throws -> Any {
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
      let length = try decoder.readVarint()
      let data = try decoder.readBytes(Int(length))
      guard let string = String(data: data, encoding: .utf8) else {
        throw DeserializationError.invalidUTF8String
      }
      return string

    case .bytes:
      let length = try decoder.readVarint()
      return try decoder.readBytes(Int(length))

    case .message:
      guard let typeName = typeName else {
        throw DeserializationError.missingTypeName(fieldType: "message")
      }

      let length = try decoder.readVarint()
      _ = try decoder.readBytes(Int(length))

      // For nested message deserialization we need its descriptor
      // In real implementation this should be obtained from TypeRegistry
      // For now using stub
      throw DeserializationError.unsupportedNestedMessage(typeName: typeName)

    case .enum:
      let varint = try decoder.readVarint()
      return Int32(truncatingIfNeeded: varint)

    case .group:
      throw DeserializationError.unsupportedFieldType(type: "group")
    }
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

    case .startGroup, .endGroup:
      throw DeserializationError.unsupportedFieldType(type: "group")
    }

    let endPosition = decoder.position
    return decoder.data.subdata(in: startPosition..<endPosition)
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

  /// Creates deserialization options.
  public init(preserveUnknownFields: Bool = true, strictUTF8Validation: Bool = true) {
    self.preserveUnknownFields = preserveUnknownFields
    self.strictUTF8Validation = strictUTF8Validation
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
