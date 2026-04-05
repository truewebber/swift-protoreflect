//
// StaticMessageBridge.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// StaticMessageBridge provides conversion between static Swift Protobuf messages
/// and dynamic DynamicMessage objects.
///
/// This component allows:
/// - Converting static messages to dynamic for reflection.
/// - Creating static messages from dynamic for integration with existing code.
/// - Ensuring compatibility between static and dynamic approaches.
public struct StaticMessageBridge {

  // MARK: - Initialization

  /// Creates new StaticMessageBridge instance.
  public init() {}

  // MARK: - Static to Dynamic Conversion

  /// Converts static Swift Protobuf message to dynamic DynamicMessage.
  ///
  /// - Parameters:
  ///   - staticMessage: Static message to convert.
  ///   - descriptor: Descriptor for creating dynamic message.
  /// - Returns: Dynamic message with data from static.
  /// - Throws: Error if conversion is impossible.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T,
    using descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    // Serialize static message to binary format
    let binaryData = try staticMessage.serializedData()

    // Deserialize to dynamic message
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    return try deserializer.deserialize(binaryData, using: descriptor)
  }

  /// Converts static Swift Protobuf message to dynamic DynamicMessage
  /// with automatic descriptor creation.
  ///
  /// - Parameter staticMessage: Static message to convert.
  /// - Returns: Dynamic message with data from static.
  /// - Throws: Error if conversion is impossible or descriptor cannot be created.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> DynamicMessage {
    // Create descriptor from static message
    let descriptor = try createDescriptor(from: staticMessage)

    // Convert using created descriptor
    return try toDynamicMessage(from: staticMessage, using: descriptor)
  }

  // MARK: - Dynamic to Static Conversion

  /// Converts dynamic DynamicMessage to static Swift Protobuf message.
  ///
  /// - Parameters:
  ///   - dynamicMessage: Dynamic message to convert.
  ///   - messageType: Static message type to create.
  /// - Returns: Static message with data from dynamic.
  /// - Throws: Error if conversion is impossible.
  public func toStaticMessage<T: SwiftProtobuf.Message>(
    from dynamicMessage: DynamicMessage,
    as messageType: T.Type
  ) throws -> T {
    // Serialize dynamic message to binary format
    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(dynamicMessage)

    // Deserialize to static message
    return try T(serializedBytes: binaryData)
  }

  // MARK: - Batch Conversion Methods

  /// Converts array of static messages to array of dynamic messages.
  ///
  /// - Parameters:
  ///   - staticMessages: Array of static messages.
  ///   - descriptor: Descriptor for creating dynamic messages.
  /// - Returns: Array of dynamic messages.
  /// - Throws: Error if any conversion is impossible.
  public func toDynamicMessages<T: SwiftProtobuf.Message>(
    from staticMessages: [T],
    using descriptor: MessageDescriptor
  ) throws -> [DynamicMessage] {
    return try staticMessages.map { staticMessage in
      try toDynamicMessage(from: staticMessage, using: descriptor)
    }
  }

  /// Converts array of dynamic messages to array of static messages.
  ///
  /// - Parameters:
  ///   - dynamicMessages: Array of dynamic messages.
  ///   - messageType: Static message type to create.
  /// - Returns: Array of static messages.
  /// - Throws: Error if any conversion is impossible.
  public func toStaticMessages<T: SwiftProtobuf.Message>(
    from dynamicMessages: [DynamicMessage],
    as messageType: T.Type
  ) throws -> [T] {
    return try dynamicMessages.map { dynamicMessage in
      try toStaticMessage(from: dynamicMessage, as: messageType)
    }
  }

  // MARK: - Validation Methods

  /// Checks compatibility of static message with descriptor.
  ///
  /// - Parameters:
  ///   - staticMessage: Static message to check.
  ///   - descriptor: Descriptor for comparison.
  /// - Returns: true if message is compatible with descriptor.
  public func isCompatible<T: SwiftProtobuf.Message>(
    staticMessage: T,
    with descriptor: MessageDescriptor
  ) -> Bool {
    do {
      // Try to convert and check that no errors occur
      _ = try toDynamicMessage(from: staticMessage, using: descriptor)
      return true
    }
    catch {
      return false
    }
  }

  /// Checks compatibility of dynamic message with static message type.
  ///
  /// - Parameters:
  ///   - dynamicMessage: Dynamic message to check.
  ///   - messageType: Static message type for comparison.
  /// - Returns: true if message is compatible with type.
  public func isCompatible<T: SwiftProtobuf.Message>(
    dynamicMessage: DynamicMessage,
    with messageType: T.Type
  ) -> Bool {
    do {
      // Try to convert and check that no errors occur
      _ = try toStaticMessage(from: dynamicMessage, as: messageType)
      return true
    }
    catch {
      return false
    }
  }

  // MARK: - Helper Methods

  /// Creates MessageDescriptor from a static SwiftProtobuf message by
  /// traversing it with a `FieldExtractorVisitor` (for field numbers and
  /// types) and correlating with JSON output (for field names).
  ///
  /// - Note: Only fields that have non-default values on the instance are
  ///   extracted. Fields left at their default proto3 values will not
  ///   appear in the descriptor — this is acceptable because proto3
  ///   binary format omits default values anyway.
  ///
  /// - Parameter staticMessage: Static message.
  /// - Returns: Message descriptor.
  /// - Throws: Error if descriptor cannot be created.
  private func createDescriptor<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> MessageDescriptor {
    let messageName = T.protoMessageName

    var visitor = FieldExtractorVisitor()
    try staticMessage.traverse(visitor: &visitor)
    let fields = visitor.extractedFields

    let jsonNames = extractOrderedJSONKeys(from: staticMessage)

    var descriptor = MessageDescriptor(name: messageName, fullName: messageName)
    for (index, field) in fields.enumerated() {
      let name = index < jsonNames.count ? jsonNames[index] : "field_\(field.number)"
      descriptor.addField(
        FieldDescriptor(
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

  /// Parses ordered JSON keys from the raw JSON output of a SwiftProtobuf message.
  ///
  /// SwiftProtobuf's JSON encoder emits keys in field number order.
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

/// Visits a SwiftProtobuf message to extract field metadata.
struct FieldExtractorVisitor: SwiftProtobuf.Visitor {

  struct FieldInfo {
    let number: Int
    let type: FieldType
    let isRepeated: Bool
    let typeName: String?
  }

  private(set) var extractedFields: [FieldInfo] = []

  private mutating func record(
    _ number: Int,
    _ type: FieldType,
    repeated: Bool = false,
    typeName: String? = nil
  ) {
    if !extractedFields.contains(where: { $0.number == number }) {
      extractedFields.append(
        FieldInfo(number: number, type: type, isRepeated: repeated, typeName: typeName)
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

  // Repeated fields
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

  // Map fields
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

/// Errors that occur when working with StaticMessageBridge.
public enum StaticMessageBridgeError: Error, LocalizedError {
  case incompatibleTypes(staticType: String, descriptorType: String)
  case serializationFailed(underlying: Error)
  case deserializationFailed(underlying: Error)
  case descriptorCreationFailed(messageType: String)
  case unsupportedMessageType(String)

  public var errorDescription: String? {
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

// MARK: - Extensions

/// Extension for DynamicMessage for convenient conversion to static messages.
extension DynamicMessage {

  /// Converts this dynamic message to static Swift Protobuf message.
  ///
  /// - Parameter messageType: Static message type to create.
  /// - Returns: Static message with data from this dynamic.
  /// - Throws: Error if conversion is impossible.
  public func toStaticMessage<T: SwiftProtobuf.Message>(as messageType: T.Type) throws -> T {
    let bridge = StaticMessageBridge()
    return try bridge.toStaticMessage(from: self, as: messageType)
  }
}

/// Extension for Swift Protobuf Message for convenient conversion to dynamic messages.
extension SwiftProtobuf.Message {

  /// Converts this static message to dynamic DynamicMessage.
  ///
  /// - Parameter descriptor: Descriptor for creating dynamic message.
  /// - Returns: Dynamic message with data from this static.
  /// - Throws: Error if conversion is impossible.
  public func toDynamicMessage(using descriptor: MessageDescriptor) throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self, using: descriptor)
  }

  /// Converts this static message to dynamic DynamicMessage
  /// with automatic descriptor creation.
  ///
  /// - Returns: Dynamic message with data from this static.
  /// - Throws: Error if conversion is impossible or descriptor cannot be created.
  public func toDynamicMessage() throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self)
  }
}
