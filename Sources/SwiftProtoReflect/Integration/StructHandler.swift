/**
 * StructHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Struct - динамические JSON-like структуры
 */

import Foundation
import SwiftProtobuf

// MARK: - Struct Handler

/// Обработчик для google.protobuf.Struct.
public struct StructHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.structType
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Struct Representation

  /// Специализированное представление Struct.
  public struct StructValue: Equatable, CustomStringConvertible {

    /// Поля структуры.
    public let fields: [String: ValueValue]

    /// Инициализация с полями структуры.
    /// - Parameter fields: Словарь полей структуры.
    public init(fields: [String: ValueValue] = [:]) {
      self.fields = fields
    }

    /// Инициализация из Dictionary<String, Any>.
    /// - Parameter dictionary: Словарь с произвольными значениями.
    /// - Throws: WellKnownTypeError если конвертация невозможна.
    public init(from dictionary: [String: Any]) throws {
      var convertedFields: [String: ValueValue] = [:]

      for (key, value) in dictionary {
        convertedFields[key] = try ValueValue(from: value)
      }

      self.fields = convertedFields
    }

    /// Создает пустую структуру.
    /// - Returns: StructValue без полей.
    public static func empty() -> StructValue {
      return StructValue()
    }

    /// Проверяет, содержит ли структура указанный ключ.
    /// - Parameter key: Ключ для проверки.
    /// - Returns: true если ключ присутствует в структуре.
    public func contains(_ key: String) -> Bool {
      return fields[key] != nil
    }

    /// Получает значение по ключу.
    /// - Parameter key: Ключ поля.
    /// - Returns: ValueValue или nil если ключ не найден.
    public func getValue(_ key: String) -> ValueValue? {
      return fields[key]
    }

    /// Создает новую структуру с добавленным полем.
    /// - Parameters:
    ///   - key: Ключ поля.
    ///   - value: Значение поля.
    /// - Returns: Новая StructValue с добавленным полем.
    public func adding(_ key: String, value: ValueValue) -> StructValue {
      var newFields = fields
      newFields[key] = value
      return StructValue(fields: newFields)
    }

    /// Создает новую структуру без указанного поля.
    /// - Parameter key: Ключ поля для удаления.
    /// - Returns: Новая StructValue без указанного поля.
    public func removing(_ key: String) -> StructValue {
      var newFields = fields
      newFields.removeValue(forKey: key)
      return StructValue(fields: newFields)
    }

    /// Объединяет две структуры.
    /// - Parameter other: Другая структура для объединения.
    /// - Returns: Новая StructValue с объединенными полями (значения из other переписывают значения из self).
    public func merging(_ other: StructValue) -> StructValue {
      var newFields = fields
      for (key, value) in other.fields {
        newFields[key] = value
      }
      return StructValue(fields: newFields)
    }

    /// Конвертирует в Dictionary<String, Any>.
    /// - Returns: Словарь с произвольными значениями.
    public func toDictionary() -> [String: Any] {
      var result: [String: Any] = [:]
      for (key, value) in fields {
        result[key] = value.toAny()
      }
      return result
    }

    public var description: String {
      if fields.isEmpty {
        return "Struct(empty)"
      }

      let fieldStrings = fields.map { "\($0.key): \($0.value)" }.sorted()
      return "Struct({\(fieldStrings.joined(separator: ", "))})"
    }
  }

  // MARK: - Value Representation

  /// Специализированное представление для google.protobuf.Value.
  public enum ValueValue: Equatable, CustomStringConvertible {
    case nullValue
    case numberValue(Double)
    case stringValue(String)
    case boolValue(Bool)
    case structValue(StructValue)
    case listValue([ValueValue])

    /// Инициализация из произвольного Swift значения.
    /// - Parameter value: Произвольное значение для конвертации.
    /// - Throws: WellKnownTypeError если тип не поддерживается.
    public init(from value: Any) throws {
      switch value {
      case is NSNull:
        self = .nullValue
      case let number as NSNumber:
        // NSNumber может представлять как Bool, так и Number
        #if canImport(CoreFoundation) && !os(Linux)
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
          self = .boolValue(number.boolValue)
        } else {
          self = .numberValue(number.doubleValue)
        }
        #else
        // Cross-platform compatible way to detect boolean NSNumber on Linux
        let objCType = String(cString: number.objCType)
        if objCType == "c" || objCType == "B" { // char or Bool
          self = .boolValue(number.boolValue)
        } else {
          self = .numberValue(number.doubleValue)
        }
        #endif
      case let bool as Bool:
        self = .boolValue(bool)
      case let int as Int:
        self = .numberValue(Double(int))
      case let int32 as Int32:
        self = .numberValue(Double(int32))
      case let int64 as Int64:
        self = .numberValue(Double(int64))
      case let uint as UInt:
        self = .numberValue(Double(uint))
      case let uint32 as UInt32:
        self = .numberValue(Double(uint32))
      case let uint64 as UInt64:
        self = .numberValue(Double(uint64))
      case let float as Float:
        self = .numberValue(Double(float))
      case let double as Double:
        self = .numberValue(double)
      case let string as String:
        self = .stringValue(string)
      case let dict as [String: Any]:
        let structValue = try StructValue(from: dict)
        self = .structValue(structValue)
      case let array as [Any]:
        let listValues = try array.map { try ValueValue(from: $0) }
        self = .listValue(listValues)
      default:
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.value,
          reason: "Unsupported value type: \(type(of: value))"
        )
      }
    }

    /// Конвертирует в произвольное Swift значение.
    /// - Returns: Произвольное значение.
    public func toAny() -> Any {
      switch self {
      case .nullValue:
        return NSNull()
      case .numberValue(let number):
        return number
      case .stringValue(let string):
        return string
      case .boolValue(let bool):
        return bool
      case .structValue(let structValue):
        return structValue.toDictionary()
      case .listValue(let list):
        return list.map { $0.toAny() }
      }
    }

    public var description: String {
      switch self {
      case .nullValue:
        return "null"
      case .numberValue(let number):
        return String(number)
      case .stringValue(let string):
        return "\"\(string)\""
      case .boolValue(let bool):
        return String(bool)
      case .structValue(let structValue):
        return structValue.description
      case .listValue(let list):
        let elements = list.map { $0.description }
        return "[\(elements.joined(separator: ", "))]"
      }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Проверяем тип сообщения
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Извлекаем поле fields как Data и десериализуем JSON
    let fieldsValue: [String: Any]

    do {
      if try message.hasValue(forField: "fields") {
        let value = try message.get(forField: "fields")

        if let data = value as? Data {
          // Десериализуем JSON данные
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
          if let dict = jsonObject as? [String: Any] {
            fieldsValue = dict
          }
          else {
            fieldsValue = [:]
          }
        }
        else {
          fieldsValue = [:]
        }
      }
      else {
        fieldsValue = [:]
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "StructValue",
        reason: "Failed to extract fields: \(error.localizedDescription)"
      )
    }

    // Создаем StructValue
    return try StructValue(from: fieldsValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let structValue = specialized as? StructValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected StructValue"
      )
    }

    // Создаем дескриптор для Struct
    let structDescriptor = createStructDescriptor()

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: structDescriptor)

    // Сериализуем поля в JSON и сохраняем как Data
    let fieldsDict = structValue.toDictionary()

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: fieldsDict, options: [])
      try message.set(jsonData, forField: "fields")
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "StructValue",
        to: "DynamicMessage",
        reason: "Failed to serialize fields: \(error.localizedDescription)"
      )
    }

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is StructValue
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.Struct.
  /// - Returns: MessageDescriptor для Struct.
  private static func createStructDescriptor() -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения Struct
    var messageDescriptor = MessageDescriptor(
      name: "Struct",
      parent: fileDescriptor
    )

    // Добавляем поле fields как bytes для хранения JSON сериализованных данных
    // Это упрощенная версия для поддержки динамических структур
    let fieldsField = FieldDescriptor(
      name: "fields",
      number: 1,
      type: .bytes  // Храним JSON как бинарные данные
    )
    messageDescriptor.addField(fieldsField)

    // Регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension Dictionary where Key == String, Value == Any {

  /// Создает StructValue из словаря.
  /// - Returns: StructValue.
  /// - Throws: WellKnownTypeError если конвертация невозможна.
  public func toStructValue() throws -> StructHandler.StructValue {
    return try StructHandler.StructValue(from: self)
  }
}

extension DynamicMessage {

  /// Создает DynamicMessage из словаря для google.protobuf.Struct.
  /// - Parameter fields: Поля структуры.
  /// - Returns: DynamicMessage представляющий Struct.
  /// - Throws: WellKnownTypeError.
  public static func structMessage(from fields: [String: Any]) throws -> DynamicMessage {
    let structValue = try StructHandler.StructValue(from: fields)
    return try StructHandler.createDynamic(from: structValue)
  }

  /// Конвертирует DynamicMessage в словарь (если это Struct).
  /// - Returns: Словарь полей структуры.
  /// - Throws: WellKnownTypeError если сообщение не является Struct.
  public func toFieldsDictionary() throws -> [String: Any] {
    guard descriptor.fullName == WellKnownTypeNames.structType else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Struct"
      )
    }

    let structValue = try StructHandler.createSpecialized(from: self) as! StructHandler.StructValue
    return structValue.toDictionary()
  }
}
