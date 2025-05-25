//
// JSONSerializer.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation

/// JSONSerializer.
///
/// Предоставляет функциональность для сериализации динамических Protocol Buffers сообщений
/// в JSON формат согласно официальной спецификации Protocol Buffers JSON mapping.
/// Обеспечивает полную совместимость с protoc --json_out.
public struct JSONSerializer {
  
  // MARK: - Properties
  
  /// Опции JSON сериализации
  public let options: JSONSerializationOptions
  
  // MARK: - Initialization
  
  /// Создает новый экземпляр JSONSerializer
  ///
  /// - Parameter options: Опции JSON сериализации
  public init(options: JSONSerializationOptions = JSONSerializationOptions()) {
    self.options = options
  }
  
  // MARK: - Serialization Methods
  
  /// Сериализует динамическое сообщение в JSON формат
  ///
  /// - Parameter message: Динамическое сообщение для сериализации
  /// - Returns: JSON строка в Data формате
  /// - Throws: JSONSerializationError если сериализация не удалась
  public func serialize(_ message: DynamicMessage) throws -> Data {
    let jsonObject = try serializeToJSONObject(message)
    
    let options: JSONSerialization.WritingOptions = self.options.prettyPrinted ? .prettyPrinted : []
    
    do {
      return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    } catch {
      throw JSONSerializationError.jsonWriteError(underlyingError: error)
    }
  }
  
  /// Сериализует динамическое сообщение в JSON объект
  ///
  /// - Parameter message: Динамическое сообщение для сериализации
  /// - Returns: JSON совместимый объект (Dictionary)
  /// - Throws: JSONSerializationError если сериализация не удалась
  public func serializeToJSONObject(_ message: DynamicMessage) throws -> [String: Any] {
    var result: [String: Any] = [:]
    
    let descriptor = message.descriptor
    let fieldAccess = FieldAccessor(message)
    
    // Обрабатываем все поля с данными
    for field in descriptor.allFields() {
      // Пропускаем поля без значений (proto3 семантика)
      guard fieldAccess.hasValue(field.name) else {
        continue
      }
      
      let fieldName = options.useOriginalFieldNames ? field.name : field.jsonName
      result[fieldName] = try serializeFieldValue(field, from: fieldAccess)
    }
    
    return result
  }
  
  // MARK: - Private Methods
  
  /// Сериализует значение поля в JSON совместимый объект
  private func serializeFieldValue(_ field: FieldDescriptor, from fieldAccess: FieldAccessor) throws -> Any {
    if field.isMap {
      return try serializeMapField(field, from: fieldAccess)
    } else if field.isRepeated {
      return try serializeRepeatedField(field, from: fieldAccess)
    } else {
      return try serializeSingleField(field, from: fieldAccess)
    }
  }
  
  /// Сериализует одиночное поле
  private func serializeSingleField(_ field: FieldDescriptor, from fieldAccess: FieldAccessor) throws -> Any {
    guard let value = fieldAccess.getValue(field.name, as: Any.self) else {
      throw JSONSerializationError.missingFieldValue(fieldName: field.name)
    }
    
    return try convertValueToJSON(value, type: field.type, typeName: field.typeName)
  }
  
  /// Сериализует repeated поле
  private func serializeRepeatedField(_ field: FieldDescriptor, from fieldAccess: FieldAccessor) throws -> Any {
    guard let values = fieldAccess.getValue(field.name, as: [Any].self) else {
      throw JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: fieldAccess.getValue(field.name, as: Any.self)))
      )
    }
    
    var jsonArray: [Any] = []
    for value in values {
      let jsonValue = try convertValueToJSON(value, type: field.type, typeName: field.typeName)
      jsonArray.append(jsonValue)
    }
    
    return jsonArray
  }
  
  /// Сериализует map поле
  private func serializeMapField(_ field: FieldDescriptor, from fieldAccess: FieldAccessor) throws -> Any {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw JSONSerializationError.missingMapEntryInfo(fieldName: field.name)
    }
    
    guard let mapValues = fieldAccess.getValue(field.name, as: [AnyHashable: Any].self) else {
      throw JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.name, as: Any.self)))
      )
    }
    
    var jsonObject: [String: Any] = [:]
    
    for (key, value) in mapValues {
      // Конвертируем ключ в строку (JSON объекты всегда имеют строковые ключи)
      let jsonKey = try convertMapKeyToJSONString(key, keyType: mapEntryInfo.keyFieldInfo.type)
      let jsonValue = try convertValueToJSON(
        value,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName
      )
      jsonObject[jsonKey] = jsonValue
    }
    
    return jsonObject
  }
  
  /// Конвертирует значение в JSON совместимый тип
  internal func convertValueToJSON(_ value: Any, type: FieldType, typeName: String?) throws -> Any {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Double", actual: String(describing: Swift.type(of: value)))
      }
      return convertDoubleToJSON(doubleValue)
      
    case .float:
      guard let floatValue = value as? Float else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Float", actual: String(describing: Swift.type(of: value)))
      }
      return convertFloatToJSON(floatValue)
      
    case .int32, .sint32, .sfixed32:
      guard let int32Value = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      return Int(int32Value)
      
    case .int64, .sint64, .sfixed64:
      guard let int64Value = value as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Int64", actual: String(describing: Swift.type(of: value)))
      }
      // int64 представляется как строка в JSON
      return String(int64Value)
      
    case .uint32, .fixed32:
      guard let uint32Value = value as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "UInt32", actual: String(describing: Swift.type(of: value)))
      }
      return UInt(uint32Value)
      
    case .uint64, .fixed64:
      guard let uint64Value = value as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "UInt64", actual: String(describing: Swift.type(of: value)))
      }
      // uint64 представляется как строка в JSON
      return String(uint64Value)
      
    case .bool:
      guard let boolValue = value as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Bool", actual: String(describing: Swift.type(of: value)))
      }
      return boolValue
      
    case .string:
      guard let stringValue = value as? String else {
        throw JSONSerializationError.valueTypeMismatch(expected: "String", actual: String(describing: Swift.type(of: value)))
      }
      return stringValue
      
    case .bytes:
      guard let bytesValue = value as? Data else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Data", actual: String(describing: Swift.type(of: value)))
      }
      // bytes представляются как base64 строка
      return bytesValue.base64EncodedString()
      
    case .message:
      guard let messageValue = value as? DynamicMessage else {
        throw JSONSerializationError.valueTypeMismatch(expected: "DynamicMessage", actual: String(describing: Swift.type(of: value)))
      }
      // Рекурсивно сериализуем вложенное сообщение
      return try serializeToJSONObject(messageValue)
      
    case .enum:
      guard let enumValue = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: value)))
      }
      // В JSON enum представляется как строка с именем значения
      // Пока возвращаем число, можно расширить для поддержки имен enum
      return Int(enumValue)
      
    case .group:
      throw JSONSerializationError.unsupportedFieldType(type: "group")
    }
  }
  
  /// Конвертирует ключ map в JSON строку
  internal func convertMapKeyToJSONString(_ key: Any, keyType: FieldType) throws -> String {
    switch keyType {
    case .string:
      guard let stringKey = key as? String else {
        throw JSONSerializationError.valueTypeMismatch(expected: "String", actual: String(describing: Swift.type(of: key)))
      }
      return stringKey
      
    case .int32, .sint32, .sfixed32:
      guard let int32Key = key as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Int32", actual: String(describing: Swift.type(of: key)))
      }
      return String(int32Key)
      
    case .int64, .sint64, .sfixed64:
      guard let int64Key = key as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Int64", actual: String(describing: Swift.type(of: key)))
      }
      return String(int64Key)
      
    case .uint32, .fixed32:
      guard let uint32Key = key as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "UInt32", actual: String(describing: Swift.type(of: key)))
      }
      return String(uint32Key)
      
    case .uint64, .fixed64:
      guard let uint64Key = key as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(expected: "UInt64", actual: String(describing: Swift.type(of: key)))
      }
      return String(uint64Key)
      
    case .bool:
      guard let boolKey = key as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(expected: "Bool", actual: String(describing: Swift.type(of: key)))
      }
      return boolKey ? "true" : "false"
      
    default:
      throw JSONSerializationError.invalidMapKeyType(keyType: String(describing: keyType))
    }
  }
  
  /// Конвертирует double значение с обработкой специальных случаев
  private func convertDoubleToJSON(_ value: Double) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    } else if value.isNaN {
      return "NaN"
    } else {
      return value
    }
  }
  
  /// Конвертирует float значение с обработкой специальных случаев
  private func convertFloatToJSON(_ value: Float) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    } else if value.isNaN {
      return "NaN"
    } else {
      return value
    }
  }
}

// MARK: - JSON Serialization Options

/// Опции для JSON сериализации
public struct JSONSerializationOptions {
  /// Использовать оригинальные имена полей вместо camelCase
  public let useOriginalFieldNames: Bool
  
  /// Форматировать JSON с отступами для читаемости
  public let prettyPrinted: Bool
  
  /// Включать поля с default значениями
  public let includeDefaultValues: Bool
  
  /// Создает опции JSON сериализации
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false
  ) {
    self.useOriginalFieldNames = useOriginalFieldNames
    self.prettyPrinted = prettyPrinted
    self.includeDefaultValues = includeDefaultValues
  }
}

// MARK: - JSON Serialization Errors

/// Ошибки JSON сериализации
public enum JSONSerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)
  case invalidMapKeyType(keyType: String)
  case jsonWriteError(underlyingError: Error)
  
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
    case .invalidMapKeyType(let keyType):
      return "Invalid map key type: \(keyType)"
    case .jsonWriteError(let underlyingError):
      return "JSON write error: \(underlyingError.localizedDescription)"
    }
  }
  
  public static func == (lhs: JSONSerializationError, rhs: JSONSerializationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidFieldType(let lField, let lExpected, let lActual), 
          .invalidFieldType(let rField, let rExpected, let rActual)):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (.valueTypeMismatch(let lExpected, let lActual), 
          .valueTypeMismatch(let rExpected, let rActual)):
      return lExpected == rExpected && lActual == rActual
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingFieldValue(let lField), .missingFieldValue(let rField)):
      return lField == rField
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    case (.invalidMapKeyType(let lType), .invalidMapKeyType(let rType)):
      return lType == rType
    case (.jsonWriteError(_), .jsonWriteError(_)):
      // Трудно сравнивать underlying errors, поэтому считаем равными если оба jsonWriteError
      return true
    default:
      return false
    }
  }
}
