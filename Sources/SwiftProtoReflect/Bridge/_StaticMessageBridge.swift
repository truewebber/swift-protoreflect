//
// _StaticMessageBridge.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

internal struct _StaticMessageBridge {

  // MARK: - Static to Dynamic Conversion

  func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T,
    using descriptor: _MessageDescriptor
  ) throws -> _DynamicMessage {
    let binaryData = try staticMessage.serializedData()
    let deserializer = _BinaryDeserializer(options: .init(typeRegistry: _TypeRegistry()))
    return try deserializer.deserialize(binaryData, using: descriptor)
  }

  func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> _DynamicMessage {
    let descriptor = try createDescriptor(from: staticMessage)
    return try toDynamicMessage(from: staticMessage, using: descriptor)
  }

  // MARK: - Dynamic to Static Conversion

  func toStaticMessage<T: SwiftProtobuf.Message>(
    from dynamicMessage: _DynamicMessage,
    as messageType: T.Type
  ) throws -> T {
    let serializer = _BinarySerializer()
    let binaryData = try serializer.serialize(dynamicMessage)
    return try T(serializedBytes: binaryData)
  }

  // MARK: - Batch Conversions

  func toDynamicMessages<T: SwiftProtobuf.Message>(
    from staticMessages: [T],
    using descriptor: _MessageDescriptor
  ) throws -> [_DynamicMessage] {
    return try staticMessages.map { try toDynamicMessage(from: $0, using: descriptor) }
  }

  func toStaticMessages<T: SwiftProtobuf.Message>(
    from dynamicMessages: [_DynamicMessage],
    as messageType: T.Type
  ) throws -> [T] {
    return try dynamicMessages.map { try toStaticMessage(from: $0, as: messageType) }
  }

  // MARK: - Compatibility Checks

  func isCompatible<T: SwiftProtobuf.Message>(
    staticMessage: T,
    with descriptor: _MessageDescriptor
  ) -> Bool {
    guard let binaryData = try? staticMessage.serializedData() else { return false }
    return
      (try? _BinaryDeserializer(options: .init(typeRegistry: _TypeRegistry()))
      .deserialize(binaryData, using: descriptor)) != nil
  }

  func isCompatible<T: SwiftProtobuf.Message>(
    dynamicMessage: _DynamicMessage,
    with messageType: T.Type
  ) -> Bool {
    guard let binaryData = try? _BinarySerializer().serialize(dynamicMessage) else { return false }
    return (try? T(serializedBytes: binaryData)) != nil
  }

  // MARK: - Helper Methods

  private func createDescriptor<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> _MessageDescriptor {
    let messageName = T.protoMessageName

    var visitor = _FieldExtractorVisitor()
    try staticMessage.traverse(visitor: &visitor)
    let fields = visitor.extractedFields

    let jsonNames = extractOrderedJSONKeys(from: staticMessage)

    var descriptor = _MessageDescriptor(name: messageName, fullName: messageName)
    for (index, field) in fields.enumerated() {
      let name = index < jsonNames.count ? jsonNames[index] : "field_\(field.number)"
      descriptor.addField(
        _FieldDescriptor(
          name: name,
          number: field.number,
          type: field.type,
          typeName: field.typeName,
          isRepeated: field.isRepeated
        )
      )
    }

    return descriptor
  }

  private func extractOrderedJSONKeys<T: SwiftProtobuf.Message>(from message: T) -> [String] {
    guard let jsonData = try? message.jsonUTF8Data(),
      let raw = String(data: jsonData, encoding: .utf8)
    else {
      return []
    }

    var keys: [String] = []
    var i = raw.startIndex
    let end = raw.endIndex
    var depth = 0

    while i < end {
      let c = raw[i]
      if c == "{" || c == "[" {
        depth += 1
      }
      else if c == "}" || c == "]" {
        depth -= 1
      }
      else if c == "\"" && depth == 1 {
        let afterQuote = raw.index(after: i)
        guard let closingQuote = raw[afterQuote...].firstIndex(of: "\"") else { break }
        let key = String(raw[afterQuote..<closingQuote])
        let afterClosing = raw.index(after: closingQuote)
        if afterClosing < end {
          let rest = raw[afterClosing...].drop(while: { $0 == " " || $0 == "\t" })
          if rest.first == ":" {
            keys.append(key)
          }
        }
      }
      i = raw.index(after: i)
    }

    return keys
  }
}

// MARK: - FieldExtractorVisitor

internal struct _FieldExtractorVisitor: SwiftProtobuf.Visitor {

  struct _FieldInfo {
    let number: Int
    let type: _FieldType
    let isRepeated: Bool
    let typeName: String?
  }

  private(set) var extractedFields: [_FieldInfo] = []

  private mutating func record(
    _ number: Int,
    _ type: _FieldType,
    repeated: Bool = false,
    typeName: String? = nil
  ) {
    if !extractedFields.contains(where: { $0.number == number }) {
      extractedFields.append(
        _FieldInfo(number: number, type: type, isRepeated: repeated, typeName: typeName)
      )
    }
  }

  mutating func visitSingularDoubleField(value: Double, fieldNumber: Int) throws {
    record(fieldNumber, .double)
  }
  mutating func visitSingularInt64Field(value: Int64, fieldNumber: Int) throws {
    record(fieldNumber, .int64)
  }
  mutating func visitSingularUInt64Field(value: UInt64, fieldNumber: Int) throws {
    record(fieldNumber, .uint64)
  }
  mutating func visitSingularBoolField(value: Bool, fieldNumber: Int) throws {
    record(fieldNumber, .bool)
  }
  mutating func visitSingularStringField(value: String, fieldNumber: Int) throws {
    record(fieldNumber, .string)
  }
  mutating func visitSingularBytesField(value: Data, fieldNumber: Int) throws {
    record(fieldNumber, .bytes)
  }
  mutating func visitSingularFloatField(value: Float, fieldNumber: Int) throws {
    record(fieldNumber, .float)
  }
  mutating func visitSingularInt32Field(value: Int32, fieldNumber: Int) throws {
    record(fieldNumber, .int32)
  }
  mutating func visitSingularUInt32Field(value: UInt32, fieldNumber: Int) throws {
    record(fieldNumber, .uint32)
  }
  mutating func visitSingularSInt32Field(value: Int32, fieldNumber: Int) throws {
    record(fieldNumber, .sint32)
  }
  mutating func visitSingularSInt64Field(value: Int64, fieldNumber: Int) throws {
    record(fieldNumber, .sint64)
  }
  mutating func visitSingularFixed32Field(value: UInt32, fieldNumber: Int) throws {
    record(fieldNumber, .fixed32)
  }
  mutating func visitSingularFixed64Field(value: UInt64, fieldNumber: Int) throws {
    record(fieldNumber, .fixed64)
  }
  mutating func visitSingularSFixed32Field(value: Int32, fieldNumber: Int) throws {
    record(fieldNumber, .sfixed32)
  }
  mutating func visitSingularSFixed64Field(value: Int64, fieldNumber: Int) throws {
    record(fieldNumber, .sfixed64)
  }
  mutating func visitSingularEnumField<E: SwiftProtobuf.Enum>(value: E, fieldNumber: Int) throws {
    record(fieldNumber, .enum, typeName: String(describing: E.self))
  }
  mutating func visitSingularMessageField<M: SwiftProtobuf.Message>(
    value: M,
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .message, typeName: M.protoMessageName)
  }
  mutating func visitSingularGroupField<G: SwiftProtobuf.Message>(
    value: G,
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .group, typeName: G.protoMessageName)
  }

  mutating func visitRepeatedDoubleField(value: [Double], fieldNumber: Int) throws {
    record(fieldNumber, .double, repeated: true)
  }
  mutating func visitRepeatedInt64Field(value: [Int64], fieldNumber: Int) throws {
    record(fieldNumber, .int64, repeated: true)
  }
  mutating func visitRepeatedUInt64Field(value: [UInt64], fieldNumber: Int) throws {
    record(fieldNumber, .uint64, repeated: true)
  }
  mutating func visitRepeatedBoolField(value: [Bool], fieldNumber: Int) throws {
    record(fieldNumber, .bool, repeated: true)
  }
  mutating func visitRepeatedStringField(value: [String], fieldNumber: Int) throws {
    record(fieldNumber, .string, repeated: true)
  }
  mutating func visitRepeatedBytesField(value: [Data], fieldNumber: Int) throws {
    record(fieldNumber, .bytes, repeated: true)
  }
  mutating func visitRepeatedFloatField(value: [Float], fieldNumber: Int) throws {
    record(fieldNumber, .float, repeated: true)
  }
  mutating func visitRepeatedInt32Field(value: [Int32], fieldNumber: Int) throws {
    record(fieldNumber, .int32, repeated: true)
  }
  mutating func visitRepeatedUInt32Field(value: [UInt32], fieldNumber: Int) throws {
    record(fieldNumber, .uint32, repeated: true)
  }
  mutating func visitRepeatedSInt32Field(value: [Int32], fieldNumber: Int) throws {
    record(fieldNumber, .sint32, repeated: true)
  }
  mutating func visitRepeatedSInt64Field(value: [Int64], fieldNumber: Int) throws {
    record(fieldNumber, .sint64, repeated: true)
  }
  mutating func visitRepeatedFixed32Field(value: [UInt32], fieldNumber: Int) throws {
    record(fieldNumber, .fixed32, repeated: true)
  }
  mutating func visitRepeatedFixed64Field(value: [UInt64], fieldNumber: Int) throws {
    record(fieldNumber, .fixed64, repeated: true)
  }
  mutating func visitRepeatedSFixed32Field(value: [Int32], fieldNumber: Int) throws {
    record(fieldNumber, .sfixed32, repeated: true)
  }
  mutating func visitRepeatedSFixed64Field(value: [Int64], fieldNumber: Int) throws {
    record(fieldNumber, .sfixed64, repeated: true)
  }
  mutating func visitRepeatedEnumField<E: SwiftProtobuf.Enum>(
    value: [E],
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .enum, repeated: true, typeName: String(describing: E.self))
  }
  mutating func visitRepeatedMessageField<M: SwiftProtobuf.Message>(
    value: [M],
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .message, repeated: true, typeName: M.protoMessageName)
  }
  mutating func visitRepeatedGroupField<G: SwiftProtobuf.Message>(
    value: [G],
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .group, repeated: true, typeName: G.protoMessageName)
  }

  mutating func visitMapField<KeyType, ValueType: MapValueType>(
    fieldType: _ProtobufMap<KeyType, ValueType>.Type,
    value: _ProtobufMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .message, repeated: true)
  }
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufEnumMap<KeyType, ValueType>.Type,
    value: _ProtobufEnumMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws where ValueType.RawValue == Int {
    record(fieldNumber, .message, repeated: true)
  }
  mutating func visitMapField<KeyType, ValueType>(
    fieldType: _ProtobufMessageMap<KeyType, ValueType>.Type,
    value: _ProtobufMessageMap<KeyType, ValueType>.BaseType,
    fieldNumber: Int
  ) throws {
    record(fieldNumber, .message, repeated: true)
  }

  mutating func visitUnknown(bytes: Data) throws {}
}

internal enum _StaticMessageBridgeError: Error, LocalizedError {
  case incompatibleTypes(staticType: String, descriptorType: String)
  case serializationFailed(underlying: Error)
  case deserializationFailed(underlying: Error)
  case descriptorCreationFailed(messageType: String)
  case unsupportedMessageType(String)

  var errorDescription: String? {
    switch self {
    case .incompatibleTypes(let staticType, let descriptorType):
      return "Incompatible types: static type '\(staticType)' does not match descriptor '\(descriptorType)'"
    case .serializationFailed(let underlying):
      return "Serialization error: \(underlying.localizedDescription)"
    case .deserializationFailed(let underlying):
      return "Deserialization error: \(underlying.localizedDescription)"
    case .descriptorCreationFailed(let messageType):
      return "Failed to create descriptor for message type '\(messageType)'"
    case .unsupportedMessageType(let messageType):
      return "Unsupported message type: '\(messageType)'"
    }
  }
}
