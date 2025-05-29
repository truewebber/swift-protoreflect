//
// BinarySerializer.swift
// SwiftProtoReflect
//
// Создан: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// BinarySerializer.
///
/// Предоставляет функциональность для сериализации динамических Protocol Buffers сообщений.
/// в бинарный wire format, используя интеграцию с библиотекой Swift Protobuf.
/// для обеспечения совместимости со стандартом Protocol Buffers.
public struct BinarySerializer {

  // MARK: - Properties

  /// Опции сериализации.
  public let options: SerializationOptions

  // MARK: - Initialization

  /// Создает новый экземпляр BinarySerializer.
  ///
  /// - Parameter options: Опции сериализации.
  public init(options: SerializationOptions = SerializationOptions()) {
    self.options = options
  }

  // MARK: - Serialization Methods

  /// Сериализует динамическое сообщение в бинарный формат.
  ///
  /// - Parameter message: Динамическое сообщение для сериализации.
  /// - Returns: Сериализованные данные в бинарном формате.
  /// - Throws: SerializationError если сериализация не удалась.
  public func serialize(_ message: DynamicMessage) throws -> Data {
    var encoder = BinaryEncoder()
    try encodeMessage(message, to: &encoder)
    return encoder.data
  }

  // MARK: - Private Methods

  /// Кодирует сообщение в binary encoder.
  private func encodeMessage(_ message: DynamicMessage, to encoder: inout BinaryEncoder) throws {
    let descriptor = message.descriptor

    // Получаем все поля с данными
    let fieldAccess = FieldAccessor(message)

    // Сортируем поля по номерам для детерминированного вывода
    let sortedFields = descriptor.allFields().sorted { $0.number < $1.number }

    for field in sortedFields where fieldAccess.hasValue(field.name) {

      try encodeField(field, from: message, to: &encoder)
    }
  }

  /// Кодирует отдельное поле.
  private func encodeField(_ field: FieldDescriptor, from message: DynamicMessage, to encoder: inout BinaryEncoder)
    throws
  {
    let fieldAccess = FieldAccessor(message)

    if field.isMap {
      try encodeMapField(field, from: fieldAccess, to: &encoder)
    }
    else if field.isRepeated {
      try encodeRepeatedField(field, from: fieldAccess, to: &encoder)
    }
    else {
      try encodeSingleField(field, from: fieldAccess, to: &encoder)
    }
  }

  /// Кодирует одиночное поле.
  private func encodeSingleField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    to encoder: inout BinaryEncoder
  ) throws {
    guard let value = fieldAccess.getValue(field.name, as: Any.self) else {
      throw SerializationError.missingFieldValue(fieldName: field.name)
    }

    let tag = UInt32((UInt32(field.number) << 3) | wireType(for: field.type).rawValue)
    encoder.writeVarint(UInt64(tag))

    try encodeValue(value, type: field.type, typeName: field.typeName, to: &encoder)
  }

  /// Кодирует repeated поле.
  private func encodeRepeatedField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    to encoder: inout BinaryEncoder
  ) throws {
    guard let values = fieldAccess.getValue(field.name, as: [Any].self) else {
      throw SerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: fieldAccess.getValue(field.name, as: Any.self)))
      )
    }

    // Для packed repeated fields (числовые типы в proto3)
    if isPackable(field.type) && options.usePackedRepeated {
      try encodePackedRepeatedField(field, values: values, to: &encoder)
    }
    else {
      // Обычная кодировка repeated field
      for value in values {
        let tag = UInt32((UInt32(field.number) << 3) | wireType(for: field.type).rawValue)
        encoder.writeVarint(UInt64(tag))
        try encodeValue(value, type: field.type, typeName: field.typeName, to: &encoder)
      }
    }
  }

  /// Кодирует packed repeated поле.
  private func encodePackedRepeatedField(_ field: FieldDescriptor, values: [Any], to encoder: inout BinaryEncoder)
    throws
  {
    let tag = UInt32((UInt32(field.number) << 3) | WireType.lengthDelimited.rawValue)
    encoder.writeVarint(UInt64(tag))

    // Вычисляем размер packed данных
    var packedData = Data()
    var packedEncoder = BinaryEncoder(data: packedData)

    for value in values {
      try encodeValue(value, type: field.type, typeName: field.typeName, to: &packedEncoder)
    }

    packedData = packedEncoder.data
    encoder.writeVarint(UInt64(packedData.count))
    encoder.writeRawData(packedData)
  }

  /// Кодирует map поле.
  private func encodeMapField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    to encoder: inout BinaryEncoder
  ) throws {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw SerializationError.missingMapEntryInfo(fieldName: field.name)
    }

    guard let mapValues = fieldAccess.getValue(field.name, as: [AnyHashable: Any].self) else {
      throw SerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.name, as: Any.self)))
      )
    }

    // Map кодируется как repeated message entries
    for (key, value) in mapValues {
      let tag = UInt32((UInt32(field.number) << 3) | WireType.lengthDelimited.rawValue)
      encoder.writeVarint(UInt64(tag))

      // Кодируем map entry как message
      var entryData = Data()
      var entryEncoder = BinaryEncoder(data: entryData)

      // Key field (всегда номер 1)
      let keyTag = UInt32((1 << 3) | wireType(for: mapEntryInfo.keyFieldInfo.type).rawValue)
      entryEncoder.writeVarint(UInt64(keyTag))
      try encodeValue(key, type: mapEntryInfo.keyFieldInfo.type, typeName: nil, to: &entryEncoder)

      // Value field (всегда номер 2)
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

  /// Кодирует значение определенного типа.
  private func encodeValue(_ value: Any, type: FieldType, typeName: String?, to encoder: inout BinaryEncoder) throws {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw SerializationError.valueTypeMismatch(
          expected: "Double",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeDouble(doubleValue)

    case .float:
      guard let floatValue = value as? Float else {
        throw SerializationError.valueTypeMismatch(expected: "Float", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeFloat(floatValue)

    case .int32:
      guard let int32Value = value as? Int32 else {
        throw SerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(UInt64(bitPattern: Int64(int32Value)))

    case .int64:
      guard let int64Value = value as? Int64 else {
        throw SerializationError.valueTypeMismatch(expected: "Int64", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(UInt64(bitPattern: int64Value))

    case .uint32:
      guard let uint32Value = value as? UInt32 else {
        throw SerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(UInt64(uint32Value))

    case .uint64:
      guard let uint64Value = value as? UInt64 else {
        throw SerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeVarint(uint64Value)

    case .sint32:
      guard let sint32Value = value as? Int32 else {
        throw SerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(UInt64(BinarySerializer.zigzagEncode32(sint32Value)))

    case .sint64:
      guard let sint64Value = value as? Int64 else {
        throw SerializationError.valueTypeMismatch(expected: "Int64", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(BinarySerializer.zigzagEncode64(sint64Value))

    case .fixed32:
      guard let fixed32Value = value as? UInt32 else {
        throw SerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed32(fixed32Value)

    case .fixed64:
      guard let fixed64Value = value as? UInt64 else {
        throw SerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      encoder.writeFixed64(fixed64Value)

    case .sfixed32:
      guard let sfixed32Value = value as? Int32 else {
        throw SerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeFixed32(UInt32(bitPattern: sfixed32Value))

    case .sfixed64:
      guard let sfixed64Value = value as? Int64 else {
        throw SerializationError.valueTypeMismatch(expected: "Int64", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeFixed64(UInt64(bitPattern: sfixed64Value))

    case .bool:
      guard let boolValue = value as? Bool else {
        throw SerializationError.valueTypeMismatch(expected: "Bool", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(boolValue ? 1 : 0)

    case .string:
      guard let stringValue = value as? String else {
        throw SerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: value))
        )
      }
      let utf8Data = stringValue.data(using: .utf8) ?? Data()
      encoder.writeVarint(UInt64(utf8Data.count))
      encoder.writeRawData(utf8Data)

    case .bytes:
      guard let bytesValue = value as? Data else {
        throw SerializationError.valueTypeMismatch(expected: "Data", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(UInt64(bytesValue.count))
      encoder.writeRawData(bytesValue)

    case .message:
      guard let messageValue = value as? DynamicMessage else {
        throw SerializationError.valueTypeMismatch(
          expected: "DynamicMessage",
          actual: String(describing: Swift.type(of: value))
        )
      }

      // Кодируем вложенное сообщение
      var nestedData = Data()
      var nestedEncoder = BinaryEncoder(data: nestedData)
      try encodeMessage(messageValue, to: &nestedEncoder)

      nestedData = nestedEncoder.data
      encoder.writeVarint(UInt64(nestedData.count))
      encoder.writeRawData(nestedData)

    case .enum:
      guard let enumValue = value as? Int32 else {
        throw SerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      encoder.writeVarint(UInt64(bitPattern: Int64(enumValue)))

    case .group:
      throw SerializationError.unsupportedFieldType(type: "group")
    }
  }

  /// Определяет wire type для поля.
  private func wireType(for fieldType: FieldType) -> WireType {
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

  /// Проверяет, может ли тип поля быть packed.
  private func isPackable(_ fieldType: FieldType) -> Bool {
    switch fieldType {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .enum:
      return true
    case .string, .bytes, .message, .group:
      return false
    }
  }

  // MARK: - ZigZag Encoding

  /// ZigZag кодирование для 32-битных чисел со знаком.
  static func zigzagEncode32(_ value: Int32) -> UInt32 {
    return UInt32(bitPattern: (value << 1) ^ (value >> 31))
  }

  /// ZigZag кодирование для 64-битных чисел со знаком.
  static func zigzagEncode64(_ value: Int64) -> UInt64 {
    return UInt64(bitPattern: (value << 1) ^ (value >> 63))
  }
}

// MARK: - Binary Encoder

/// Низкоуровневый binary encoder для Protocol Buffers wire format.
private struct BinaryEncoder {
  private(set) var data: Data

  init(data: Data = Data()) {
    self.data = data
  }

  /// Записывает varint значение.
  mutating func writeVarint(_ value: UInt64) {
    var val = value
    while val >= 0x80 {
      data.append(UInt8(val & 0x7F | 0x80))
      val >>= 7
    }
    data.append(UInt8(val & 0x7F))
  }

  /// Записывает 32-битное fixed значение.
  mutating func writeFixed32(_ value: UInt32) {
    withUnsafeBytes(of: value.littleEndian) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  /// Записывает 64-битное fixed значение.
  mutating func writeFixed64(_ value: UInt64) {
    withUnsafeBytes(of: value.littleEndian) { bytes in
      data.append(contentsOf: bytes)
    }
  }

  /// Записывает float значение.
  mutating func writeFloat(_ value: Float) {
    writeFixed32(value.bitPattern)
  }

  /// Записывает double значение.
  mutating func writeDouble(_ value: Double) {
    writeFixed64(value.bitPattern)
  }

  /// Записывает сырые данные.
  mutating func writeRawData(_ rawData: Data) {
    data.append(rawData)
  }
}

// MARK: - Serialization Options

/// Опции для сериализации.
public struct SerializationOptions {
  /// Использовать ли packed encoding для repeated числовых полей.
  public let usePackedRepeated: Bool

  /// Создает опции сериализации.
  public init(usePackedRepeated: Bool = true) {
    self.usePackedRepeated = usePackedRepeated
  }
}

// MARK: - Serialization Errors

/// Ошибки сериализации.
public enum SerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)

  public var description: String {
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
