//
// FieldDescriptor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-18
//

import Foundation
import SwiftProtobuf

/// FieldDescriptor
///
/// Дескриптор поля Protocol Buffers, описывающий свойства поля сообщения,
/// включая его тип, имя, номер, опции и другие метаданные.
public struct FieldDescriptor: Equatable {
  // MARK: - Properties
  
  /// Имя поля (например, "first_name")
  public let name: String
  
  /// JSON имя поля (если отличается от name)
  public let jsonName: String
  
  /// Номер поля в сообщении
  public let number: Int
  
  /// Тип поля (int32, string, message и т.д.)
  public let type: FieldType
  
  /// Полное имя типа сообщения или перечисления (для типов message и enum)
  public let typeName: String?
  
  /// Указывает, является ли поле массивом (repeated)
  public let isRepeated: Bool
  
  /// Указывает, является ли поле опциональным (optional)
  public let isOptional: Bool
  
  /// Указывает, является ли поле обязательным (required) - устаревшее для proto3
  public let isRequired: Bool
  
  /// Указывает, является ли поле мапой (map<key, value>)
  public let isMap: Bool
  
  /// Указывает, является ли поле oneof частью группы
  public let oneofIndex: Int?
  
  /// Содержит метаданные для полей map типа
  public let mapEntryInfo: MapEntryInfo?
  
  /// Значение по умолчанию для поля (если определено)
  public let defaultValue: Any?
  
  /// Опции поля
  public let options: [String: Any]
  
  // MARK: - Initialization
  
  /// Создает новый экземпляр FieldDescriptor
  ///
  /// - Parameters:
  ///   - name: Имя поля
  ///   - number: Номер поля
  ///   - type: Тип поля
  ///   - typeName: Полное имя типа (для message и enum)
  ///   - jsonName: JSON имя поля (по умолчанию равно name)
  ///   - isRepeated: Является ли поле массивом
  ///   - isOptional: Является ли поле опциональным
  ///   - isRequired: Является ли поле обязательным
  ///   - isMap: Является ли поле мапой
  ///   - oneofIndex: Индекс oneof группы, если поле является частью oneof
  ///   - mapEntryInfo: Метаданные для map полей
  ///   - defaultValue: Значение по умолчанию
  ///   - options: Опции поля
  public init(
    name: String,
    number: Int,
    type: FieldType,
    typeName: String? = nil,
    jsonName: String? = nil,
    isRepeated: Bool = false,
    isOptional: Bool = false,
    isRequired: Bool = false,
    isMap: Bool = false,
    oneofIndex: Int? = nil,
    mapEntryInfo: MapEntryInfo? = nil,
    defaultValue: Any? = nil,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
    self.jsonName = jsonName ?? name
    self.isRepeated = isRepeated
    self.isOptional = isOptional
    self.isRequired = isRequired
    self.isMap = isMap
    self.oneofIndex = oneofIndex
    self.mapEntryInfo = mapEntryInfo
    self.defaultValue = defaultValue
    self.options = options
    
    // Валидация: убедиться, что typeName задан для message и enum типов
    if case .message = type, typeName == nil {
      fatalError("typeName должен быть указан для полей типа 'message'")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName должен быть указан для полей типа 'enum'")
    }
    
    // Валидация: убедиться, что для map указаны нужные параметры
    if isMap && mapEntryInfo == nil {
      fatalError("mapEntryInfo должен быть указан для полей типа 'map'")
    }
  }
  
  // MARK: - Methods
  
  /// Возвращает полное имя типа для сообщений и перечислений
  ///
  /// - Returns: Полное имя типа или nil для скалярных типов
  public func getFullTypeName() -> String? {
    return typeName
  }
  
  /// Проверяет, является ли поле скалярным типом
  ///
  /// - Returns: true, если поле имеет скалярный тип
  public func isScalarType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
         .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
         .bool, .string, .bytes:
      return true
    case .message, .enum, .group:
      return false
    }
  }
  
  /// Проверяет, является ли поле числовым типом
  ///
  /// - Returns: true, если поле имеет числовой тип
  public func isNumericType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
         .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64:
      return true
    case .bool, .string, .bytes, .message, .enum, .group:
      return false
    }
  }
  
  /// Получает информацию о ключе и значении для map полей
  ///
  /// - Returns: Информация о map поле или nil, если поле не map
  public func getMapKeyValueInfo() -> MapEntryInfo? {
    guard isMap else {
      return nil
    }
    
    return mapEntryInfo
  }
  
  // MARK: - Equatable
  
  public static func == (lhs: FieldDescriptor, rhs: FieldDescriptor) -> Bool {
    // Сравниваем основные свойства
    guard lhs.name == rhs.name &&
          lhs.jsonName == rhs.jsonName &&
          lhs.number == rhs.number &&
          lhs.type == rhs.type &&
          lhs.typeName == rhs.typeName &&
          lhs.isRepeated == rhs.isRepeated &&
          lhs.isOptional == rhs.isOptional &&
          lhs.isRequired == rhs.isRequired &&
          lhs.isMap == rhs.isMap &&
          lhs.oneofIndex == rhs.oneofIndex &&
          lhs.mapEntryInfo == rhs.mapEntryInfo else {
      return false
    }
    
    // Сравниваем options: проверяем ключи и значения
    // Может потребоваться индивидуальное сравнение для каждого возможного типа значения
    let lhsKeys = Set(lhs.options.keys)
    let rhsKeys = Set(rhs.options.keys)
    
    guard lhsKeys == rhsKeys else {
      return false
    }
    
    // Проверяем совпадение значений для всех ключей
    for key in lhsKeys {
      // Поскольку options имеет тип [String: Any], мы можем проверить только строковое представление
      // или, где возможно, преобразовать к известным типам
      let lhsValue = lhs.options[key]
      let rhsValue = rhs.options[key]
      
      // Проверяем известные типы значений
      if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
        if lhsBool != rhsBool {
          return false
        }
      } else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
        if lhsInt != rhsInt {
          return false
        }
      } else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
        if lhsString != rhsString {
          return false
        }
      } else {
        // Для других типов, сравниваем строковые представления
        if String(describing: lhsValue) != String(describing: rhsValue) {
          return false
        }
      }
    }
    
    return true
  }
}

/// Тип поля Protocol Buffers
public enum FieldType: Equatable {
  case double
  case float
  case int32
  case int64
  case uint32
  case uint64
  case sint32
  case sint64
  case fixed32
  case fixed64
  case sfixed32
  case sfixed64
  case bool
  case string
  case bytes
  case message
  case `enum`
  case group  // Устаревшее, для совместимости с proto2
}

/// Класс, описывающий метаданные для полей типа map<key, value>
/// Использует reference-type, чтобы избежать циклических ссылок
public final class MapEntryInfo: Equatable {
  /// Информация о поле ключа
  public let keyFieldInfo: KeyFieldInfo
  
  /// Информация о поле значения
  public let valueFieldInfo: ValueFieldInfo
  
  /// Создает новый экземпляр MapEntryInfo
  ///
  /// - Parameters:
  ///   - keyFieldInfo: Информация о поле ключа
  ///   - valueFieldInfo: Информация о поле значения
  public init(keyFieldInfo: KeyFieldInfo, valueFieldInfo: ValueFieldInfo) {
    // Проверка типа ключа (должен быть скалярным, кроме float, double, bytes)
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string
    ]
    
    guard validKeyTypes.contains(keyFieldInfo.type) else {
      fatalError("Недопустимый тип ключа для map: \(keyFieldInfo.type)")
    }
    
    self.keyFieldInfo = keyFieldInfo
    self.valueFieldInfo = valueFieldInfo
  }
  
  public static func == (lhs: MapEntryInfo, rhs: MapEntryInfo) -> Bool {
    return lhs.keyFieldInfo == rhs.keyFieldInfo &&
           lhs.valueFieldInfo == rhs.valueFieldInfo
  }
}

/// Информация о поле ключа в map
public struct KeyFieldInfo: Equatable {
  public let name: String
  public let number: Int
  public let type: FieldType
  
  public init(name: String, number: Int, type: FieldType) {
    self.name = name
    self.number = number
    self.type = type
  }
}

/// Информация о поле значения в map
public struct ValueFieldInfo: Equatable {
  public let name: String
  public let number: Int
  public let type: FieldType
  public let typeName: String?
  
  public init(name: String, number: Int, type: FieldType, typeName: String? = nil) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
    
    if case .message = type, typeName == nil {
      fatalError("typeName должен быть указан для полей типа 'message'")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName должен быть указан для полей типа 'enum'")
    }
  }
}
