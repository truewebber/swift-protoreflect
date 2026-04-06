//
// _BinarySerializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

internal struct _BinarySerializer: Sendable {

  // MARK: - Properties

  let options: _SerializationOptions

  // MARK: - Initialization

  init(options: _SerializationOptions = _SerializationOptions()) {
    self.options = options
  }

  // MARK: - Serialization Methods

  func serialize(_ message: _DynamicMessage) throws -> Data {
    var encoder = _BinaryEncoder()
    try encodeMessage(message, to: &encoder)
    return encoder.data
  }

  // MARK: - Private Methods

  private func encodeMessage(_ message: _DynamicMessage, to encoder: inout _BinaryEncoder) throws {
    let descriptor = message.descriptor
    let fieldAccess = _FieldAccessor(message)

    var allFields = descriptor.allFields()
    allFields.append(contentsOf: descriptor.extensions.values)
    let sortedFields = allFields.sorted { $0.number < $1.number }

    for field in sortedFields where fieldAccess.hasValue(field.number) {
      if descriptor.syntax == "proto3"
        && isProto3ImplicitPresenceScalar(field)
        && isProto3ScalarDefault(fieldAccess.getValue(field.number, as: Any.self), type: field.type)
      {
        continue
      }
      try encodeField(field, from: message, to: &encoder)
    }

    if !message.unknownFields.isEmpty {
      encoder.writeRawData(message.unknownFields)
    }
  }

  private func encodeField(_ field: _FieldDescriptor, from message: _DynamicMessage, to encoder: inout _BinaryEncoder)
    throws
  {
    let fieldAccess = _FieldAccessor(message)
    let syntax = message.descriptor.syntax

    if field.isMap {
      try encodeMapField(field, from: fieldAccess, to: &encoder)
    }
    else if field.isRepeated {
      try encodeRepeatedField(field, from: fieldAccess, syntax: syntax, to: &encoder)
    }
    else {
      try encodeSingleField(field, from: fieldAccess, to: &encoder)
    }
  }

  private func encodeSingleField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    to encoder: inout _BinaryEncoder
  ) throws {
    guard let value = fieldAccess.getValue(field.number, as: Any.self) else {
      throw _SerializationError.missingFieldValue(fieldName: field.name)
    }

    let tag = UInt32((UInt32(field.number) << 3) | wireType(for: field.type).rawValue)
    encoder.writeVarint(UInt64(tag))

    try encodeValue(value, type: field.type, typeName: field.typeName, to: &encoder)

    if case .group = field.type {
      let endTag = UInt32((UInt32(field.number) << 3) | _WireType.endGroup.rawValue)
      encoder.writeVarint(UInt64(endTag))
    }
  }

  private func encodeRepeatedField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    syntax: String,
    to encoder: inout _BinaryEncoder
  ) throws {
    guard let values = fieldAccess.getValue(field.number, as: [Any].self) else {
      throw _SerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    if isPackable(field.type) && (field.isPacked ?? (syntax == "proto3")) {
      try encodePackedRepeatedField(field, values: values, to: &encoder)
    }
    else {
      for value in values {
        let tag = UInt32((UInt32(field.number) << 3) | wireType(for: field.type).rawValue)
        encoder.writeVarint(UInt64(tag))
        try encodeValue(value, type: field.type, typeName: field.typeName, to: &encoder)
        if case .group = field.type {
          let endTag = UInt32((UInt32(field.number) << 3) | _WireType.endGroup.rawValue)
          encoder.writeVarint(UInt64(endTag))
        }
      }
    }
  }

  private func encodePackedRepeatedField(_ field: _FieldDescriptor, values: [Any], to encoder: inout _BinaryEncoder)
    throws
  {
    let tag = UInt32((UInt32(field.number) << 3) | _WireType.lengthDelimited.rawValue)
    encoder.writeVarint(UInt64(tag))

    var packedData = Data()
    var packedEncoder = _BinaryEncoder(data: packedData)

    for value in values {
      try encodeValue(value, type: field.type, typeName: field.typeName, to: &packedEncoder)
    }

    packedData = packedEncoder.data
    encoder.writeVarint(UInt64(packedData.count))
    encoder.writeRawData(packedData)
  }

  private func encodeMapField(
    _ field: _FieldDescriptor,
    from fieldAccess: _FieldAccessor,
    to encoder: inout _BinaryEncoder
  ) throws {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw _SerializationError.missingMapEntryInfo(fieldName: field.name)
    }

    guard let mapValues = fieldAccess.getValue(field.number, as: [AnyHashable: Any].self) else {
      throw _SerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    for (key, value) in mapValues {
      let tag = UInt32((UInt32(field.number) << 3) | _WireType.lengthDelimited.rawValue)
      encoder.writeVarint(UInt64(tag))

      var entryData = Data()
      var entryEncoder = _BinaryEncoder(data: entryData)

      let keyTag = UInt32((1 << 3) | wireType(for: mapEntryInfo.keyFieldInfo.type).rawValue)
      entryEncoder.writeVarint(UInt64(keyTag))
      try encodeValue(key, type: mapEntryInfo.keyFieldInfo.type, typeName: nil, to: &entryEncoder)

      let valueTag = UInt32((2 << 3) | wireType(for: mapEntryInfo.valueFieldInfo.type).rawValue)
      entryEncoder.writeVarint(UInt64(valueTag))
      try encodeValue(
        value,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName,
        to: &entryEncoder
      )

      entryData = entryEncoder.data
      encoder.writeVarint(UInt64(entryData.count))
      encoder.writeRawData(entryData)
    }
  }

  private func encodeValue(_ value: Any, type: _FieldType, typeName: String?, to encoder: inout _BinaryEncoder) throws {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Double",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeDouble(doubleValue)

    case .float:
      guard let floatValue = value as? Float else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Float",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFloat(floatValue)

    case .int32:
      guard let int32Value = value as? Int32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(bitPattern: Int64(int32Value)))

    case .int64:
      guard let int64Value = value as? Int64 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(bitPattern: int64Value))

    case .uint32:
      guard let uint32Value = value as? UInt32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(uint32Value))

    case .uint64:
      guard let uint64Value = value as? UInt64 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(uint64Value)

    case .sint32:
      guard let sint32Value = value as? Int32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(_BinarySerializer.zigzagEncode32(sint32Value)))

    case .sint64:
      guard let sint64Value = value as? Int64 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(_BinarySerializer.zigzagEncode64(sint64Value))

    case .fixed32:
      guard let fixed32Value = value as? UInt32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed32(fixed32Value)

    case .fixed64:
      guard let fixed64Value = value as? UInt64 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed64(fixed64Value)

    case .sfixed32:
      guard let sfixed32Value = value as? Int32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed32(UInt32(bitPattern: sfixed32Value))

    case .sfixed64:
      guard let sfixed64Value = value as? Int64 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed64(UInt64(bitPattern: sfixed64Value))

    case .bool:
      guard let boolValue = value as? Bool else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(boolValue ? 1 : 0)

    case .string:
      guard let stringValue = value as? String else {
        throw _SerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: value))
        )
      }
      let utf8Data = stringValue.data(using: .utf8) ?? Data()
      encoder.writeVarint(UInt64(utf8Data.count))
      encoder.writeRawData(utf8Data)

    case .bytes:
      guard let bytesValue = value as? Data else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Data",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(bytesValue.count))
      encoder.writeRawData(bytesValue)

    case .message:
      let messageValue: _DynamicMessage
      if let m = value as? _DynamicMessage {
        messageValue = m
      }
      else if let pub = value as? DynamicMessage {
        messageValue = _DynamicMessage(from: pub)
      }
      else {
        throw _SerializationError.valueTypeMismatch(
          expected: "DynamicMessage",
          actual: String(describing: Swift.type(of: value))
        )
      }

      var nestedData = Data()
      var nestedEncoder = _BinaryEncoder(data: nestedData)
      try encodeMessage(messageValue, to: &nestedEncoder)

      nestedData = nestedEncoder.data
      encoder.writeVarint(UInt64(nestedData.count))
      encoder.writeRawData(nestedData)

    case .enum:
      guard let enumValue = value as? Int32 else {
        throw _SerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(bitPattern: Int64(enumValue)))

    case .group:
      let groupMessage: _DynamicMessage
      if let m = value as? _DynamicMessage {
        groupMessage = m
      }
      else if let pub = value as? DynamicMessage {
        groupMessage = _DynamicMessage(from: pub)
      }
      else {
        throw _SerializationError.valueTypeMismatch(
          expected: "DynamicMessage (group)",
          actual: String(describing: Swift.type(of: value))
        )
      }
      try encodeMessage(groupMessage, to: &encoder)
    }
  }

  private func wireType(for fieldType: _FieldType) -> _WireType {
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
      return .startGroup
    }
  }

  private func isPackable(_ fieldType: _FieldType) -> Bool {
    switch fieldType {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .enum:
      return true
    case .string, .bytes, .message, .group:
      return false
    }
  }

  private func isProto3ImplicitPresenceScalar(_ field: _FieldDescriptor) -> Bool {
    guard !field.proto3Optional, !field.isRequired, !field.isOptional,
      !field.isRepeated, !field.isMap,
      field.oneofIndex == nil
    else { return false }
    switch field.type {
    case .message, .group, .enum: return false
    default: return true
    }
  }

  private func isProto3ScalarDefault(_ value: Any?, type: _FieldType) -> Bool {
    guard let value else { return true }
    switch type {
    case .double: return (value as? Double) == 0.0
    case .float: return (value as? Float) == 0.0
    case .int32, .sint32, .sfixed32: return (value as? Int32) == 0
    case .int64, .sint64, .sfixed64: return (value as? Int64) == 0
    case .uint32, .fixed32: return (value as? UInt32) == 0
    case .uint64, .fixed64: return (value as? UInt64) == 0
    case .bool: return (value as? Bool) == false
    case .string: return (value as? String) == ""
    case .bytes: return (value as? Data)?.isEmpty == true
    case .enum: return (value as? Int32) == 0
    case .message, .group: return false
    }
  }

  // MARK: - ZigZag Encoding

  static func zigzagEncode32(_ value: Int32) -> UInt32 {
    return UInt32(bitPattern: (value << 1) ^ (value >> 31))
  }

  static func zigzagEncode64(_ value: Int64) -> UInt64 {
    return UInt64(bitPattern: (value << 1) ^ (value >> 63))
  }
}

// MARK: - Binary Encoder

private struct _BinaryEncoder {
  private(set) var data: Data

  init(data: Data = Data()) {
    self.data = data
  }

  mutating func writeVarint(_ value: UInt64) {
    var val = value
    while val >= 0x80 {
      data.append(UInt8(val & 0x7F | 0x80))
      val >>= 7
    }
    data.append(UInt8(val & 0x7F))
  }

  mutating func writeFixed32(_ value: UInt32) {
    withUnsafeBytes(of: value.littleEndian) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  mutating func writeFixed64(_ value: UInt64) {
    withUnsafeBytes(of: value.littleEndian) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  mutating func writeFloat(_ value: Float) {
    writeFixed32(value.bitPattern)
  }

  mutating func writeDouble(_ value: Double) {
    writeFixed64(value.bitPattern)
  }

  mutating func writeRawData(_ rawData: Data) {
    data.append(rawData)
  }
}

// MARK: - Serialization Options

internal struct _SerializationOptions: Sendable {
  let usePackedRepeated: Bool

  init(usePackedRepeated: Bool = true) {
    self.usePackedRepeated = usePackedRepeated
  }
}

// MARK: - Serialization Errors

internal enum _SerializationError: Error, Equatable, Sendable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)

  var description: String {
    switch self {
    case .invalidFieldType(let fieldName, let expectedType, let actualType):
      return "Invalid field type for field '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .valueTypeMismatch(let expected, let actual):
      return "Value type mismatch: expected \(expected), got \(actual)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingFieldValue(let fieldName):
      return "Missing value for field '\(fieldName)'"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    }
  }
}
