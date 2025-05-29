//
// BinaryDeserializer.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// BinaryDeserializer.
///
/// Предоставляет функциональность для десериализации динамических Protocol Buffers сообщений.
/// из бинарного wire format, используя интеграцию с библиотекой Swift Protobuf.
/// для обеспечения совместимости со стандартом Protocol Buffers.
public struct BinaryDeserializer {

  // MARK: - Properties

  /// Опции десериализации.
  public let options: DeserializationOptions

  // MARK: - Initialization

  /// Создает новый экземпляр BinaryDeserializer.
  ///
  /// - Parameter options: Опции десериализации.
  public init(options: DeserializationOptions = DeserializationOptions()) {
    self.options = options
  }

  // MARK: - Deserialization Methods

  /// Десериализует бинарные данные в динамическое сообщение.
  ///
  /// - Parameters:.
  ///   - data: Бинарные данные для десериализации.
  ///   - descriptor: Дескриптор сообщения для определения структуры.
  /// - Returns: Десериализованное динамическое сообщение.
  /// - Throws: DeserializationError если десериализация не удалась.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    var decoder = BinaryDecoder(data: data)
    return try decodeMessage(from: &decoder, using: descriptor)
  }

  // MARK: - Private Methods

  /// Декодирует сообщение из binary decoder.
  private func decodeMessage(from decoder: inout BinaryDecoder, using descriptor: MessageDescriptor) throws
    -> DynamicMessage
  {
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)
    var unknownFields = Data()

    while decoder.hasMoreData {
      // Читаем tag (field number + wire type)
      let tag = try decoder.readVarint()
      let fieldNumber = Int(tag >> 3)
      let wireType = WireType(rawValue: UInt32(tag & 0x7))

      guard let wireType = wireType else {
        throw DeserializationError.invalidWireType(tag: UInt32(tag))
      }

      // Ищем поле по номеру
      if let field = descriptor.field(number: fieldNumber) {
        try decodeField(field, wireType: wireType, from: &decoder, into: &message)
      }
      else {
        // Неизвестное поле - сохраняем для совместимости
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

  /// Декодирует отдельное поле.
  private func decodeField(
    _ field: FieldDescriptor,
    wireType: WireType,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {

    // Проверяем совместимость wire type с типом поля
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

  /// Декодирует одиночное поле.
  private func decodeSingleField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder)
    try message.set(value, forField: field.name)
  }

  /// Декодирует repeated поле.
  private func decodeRepeatedField(
    _ field: FieldDescriptor,
    from decoder: inout BinaryDecoder,
    into message: inout DynamicMessage
  ) throws {
    let value = try decodeValue(type: field.type, typeName: field.typeName, from: &decoder)

    // Получаем существующий массив или создаем новый
    let fieldAccess = FieldAccessor(message)
    var array: [Any] = []

    if fieldAccess.hasValue(field.name) {
      array = fieldAccess.getValue(field.name, as: [Any].self) ?? []
    }

    array.append(value)
    try message.set(array, forField: field.name)
  }

  /// Декодирует packed repeated поле.
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

  /// Декодирует map поле.
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

    // Читаем entry как обычное сообщение
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
        // Пропускаем неизвестные поля в map entry
        _ = try skipUnknownField(wireType: entryWireType, from: &decoder)
      }
    }

    if decoder.position != entryEndPosition {
      throw DeserializationError.malformedMapEntry(fieldName: field.name)
    }

    // Добавляем к существующему map или создаем новый
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

  /// Декодирует значение определенного типа.
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

      // Для десериализации вложенного сообщения нужен его дескриптор
      // В реальной реализации это должно быть получено из TypeRegistry
      // Пока используем заглушку
      throw DeserializationError.unsupportedNestedMessage(typeName: typeName)

    case .enum:
      let varint = try decoder.readVarint()
      return Int32(truncatingIfNeeded: varint)

    case .group:
      throw DeserializationError.unsupportedFieldType(type: "group")
    }
  }

  /// Пропускает неизвестное поле и возвращает его данные.
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

  /// Определяет wire type для поля.
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
      return .startGroup  // Устаревшее
    }
  }

  // MARK: - ZigZag Decoding

  /// ZigZag декодирование для 32-битных чисел со знаком.
  static func zigzagDecode32(_ value: UInt32) -> Int32 {
    let shifted = value >> 1
    let mask = UInt32(bitPattern: -Int32(value & 1))
    return Int32(bitPattern: shifted ^ mask)
  }

  /// ZigZag декодирование для 64-битных чисел со знаком.
  static func zigzagDecode64(_ value: UInt64) -> Int64 {
    let shifted = value >> 1
    let mask = UInt64(bitPattern: -Int64(value & 1))
    return Int64(bitPattern: shifted ^ mask)
  }
}

// MARK: - Binary Decoder

/// Низкоуровневый binary decoder для Protocol Buffers wire format.
private struct BinaryDecoder {
  let data: Data
  var position: Int = 0

  var hasMoreData: Bool {
    return position < data.count
  }

  init(data: Data) {
    self.data = data
  }

  /// Читает varint значение.
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

  /// Читает 32-битное fixed значение.
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

  /// Читает 64-битное fixed значение.
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

  /// Читает float значение.
  mutating func readFloat() throws -> Float {
    let bits = try readFixed32()
    return Float(bitPattern: bits)
  }

  /// Читает double значение.
  mutating func readDouble() throws -> Double {
    let bits = try readFixed64()
    return Double(bitPattern: bits)
  }

  /// Читает указанное количество байтов.
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

/// Опции для десериализации.
public struct DeserializationOptions {
  /// Сохранять ли неизвестные поля для обратной совместимости.
  public let preserveUnknownFields: Bool

  /// Строгая валидация UTF-8 строк.
  public let strictUTF8Validation: Bool

  /// Создает опции десериализации.
  public init(preserveUnknownFields: Bool = true, strictUTF8Validation: Bool = true) {
    self.preserveUnknownFields = preserveUnknownFields
    self.strictUTF8Validation = strictUTF8Validation
  }
}

// MARK: - Deserialization Errors

/// Ошибки десериализации.
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
