//
// DynamicMessage.swift
// SwiftProtoReflect
//
// Создан: 2025-05-23
//

import Foundation
import SwiftProtobuf

/// DynamicMessage.
///
/// Динамическое представление Protocol Buffers сообщения,.
/// которое позволяет создавать и манипулировать сообщениями.
/// во время выполнения без предварительной генерации кода.
public struct DynamicMessage: Equatable {
  // MARK: - Properties

  /// Дескриптор сообщения, определяющий его структуру.
  public let descriptor: MessageDescriptor

  /// Хранилище значений полей.
  private var values: [Int: Any] = [:]

  /// Хранилище для вложенных сообщений.
  private var nestedMessages: [Int: DynamicMessage] = [:]

  /// Хранилище для repeated полей.
  private var repeatedValues: [Int: [Any]] = [:]

  /// Хранилище для map полей.
  private var mapValues: [Int: [AnyHashable: Any]] = [:]

  /// Информация о том, какой oneOf активен (если есть).
  private var activeOneofFields: [Int: Int] = [:]

  // MARK: - Initialization

  /// Создает новый экземпляр DynamicMessage.
  ///
  /// - Parameter descriptor: Дескриптор сообщения.
  public init(descriptor: MessageDescriptor) {
    self.descriptor = descriptor
  }

  // MARK: - Field Access Methods

  /// Устанавливает значение поля по его имени.
  ///
  /// - Parameters:.
  ///   - value: Значение для установки.
  ///   - fieldName: Имя поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует или типы несовместимы.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try set(value, forField: field.number)
  }

  /// Устанавливает значение поля по его номеру.
  ///
  /// - Parameters:.
  ///   - value: Значение для установки.
  ///   - fieldNumber: Номер поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует или типы несовместимы.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    // Обработка oneof полей
    if let oneofIndex = field.oneofIndex {
      if let currentField = activeOneofFields[oneofIndex], currentField != fieldNumber {
        // Очищаем предыдущее значение в этой oneof группе
        clearOneofField(currentField)
      }
      activeOneofFields[oneofIndex] = fieldNumber
    }

    // Обработка различных типов полей
    if field.isRepeated {
      // Repeated поля
      if field.isMap {
        // Map поля (особый случай repeated)
        guard let mapValue = value as? [AnyHashable: Any] else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "Map<Key, Value>",
            actualValue: value
          )
        }

        try validateMapValues(mapValue, for: field)

        // Преобразуем ключи и значения в map если нужно
        var convertedMap: [AnyHashable: Any] = [:]
        for (key, val) in mapValue {
          let convertedKey = convertMapKey(key, for: field.mapEntryInfo!.keyFieldInfo)
          let convertedValue = convertMapValue(val, for: field.mapEntryInfo!.valueFieldInfo)
          convertedMap[convertedKey] = convertedValue
        }

        mapValues[fieldNumber] = convertedMap
      }
      else {
        // Обычные repeated поля
        guard let arrayValue = value as? [Any] else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "Array<\(field.type)>",
            actualValue: value
          )
        }

        // Проверяем и преобразуем все элементы массива
        var convertedArray: [Any] = []
        for (index, item) in arrayValue.enumerated() {
          try validateValue(item, for: field, itemIndex: index)
          convertedArray.append(convertToCorrectType(item, for: field))
        }

        repeatedValues[fieldNumber] = convertedArray
      }
    }
    else {
      // Обычные (не repeated) поля
      try validateValue(value, for: field)

      if case .message = field.type {
        if let dynamicMessage = value as? DynamicMessage {
          // Сохраняем вложенное динамическое сообщение
          nestedMessages[fieldNumber] = dynamicMessage
        }
        else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "DynamicMessage",
            actualValue: value
          )
        }
      }
      else {
        // Преобразуем и сохраняем обычное значение
        let convertedValue = convertToCorrectType(value, for: field)
        values[fieldNumber] = convertedValue
      }
    }

    return self
  }

  /// Получает значение поля по его имени.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Значение поля или nil, если значение не установлено.
  /// - Throws: Ошибку, если поле не существует.
  public func get(forField fieldName: String) throws -> Any? {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try get(forField: field.number)
  }

  /// Получает значение поля по его номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Значение поля или nil, если значение не установлено.
  /// - Throws: Ошибку, если поле не существует.
  public func get(forField fieldNumber: Int) throws -> Any? {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    // Определяем, откуда взять значение в зависимости от типа поля
    if field.isRepeated {
      if field.isMap {
        return mapValues[fieldNumber]
      }
      else {
        return repeatedValues[fieldNumber]
      }
    }
    else if case .message = field.type {
      return nestedMessages[fieldNumber]
    }
    else {
      return values[fieldNumber] ?? field.defaultValue
    }
  }

  /// Проверяет, было ли установлено значение для поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: true, если значение установлено.
  /// - Throws: Ошибку, если поле не существует.
  public func hasValue(forField fieldName: String) throws -> Bool {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try hasValue(forField: field.number)
  }

  /// Проверяет, было ли установлено значение для поля.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: true, если значение установлено.
  /// - Throws: Ошибку, если поле не существует.
  public func hasValue(forField fieldNumber: Int) throws -> Bool {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    if field.isRepeated {
      if field.isMap {
        return mapValues[fieldNumber] != nil
      }
      else {
        return repeatedValues[fieldNumber] != nil
      }
    }
    else if case .message = field.type {
      return nestedMessages[fieldNumber] != nil
    }
    else {
      return values[fieldNumber] != nil
    }
  }

  /// Очищает значение поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует.
  @discardableResult
  public mutating func clearField(_ fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try clearField(field.number)
  }

  /// Очищает значение поля.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует.
  @discardableResult
  public mutating func clearField(_ fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    if field.isRepeated {
      if field.isMap {
        mapValues.removeValue(forKey: fieldNumber)
      }
      else {
        repeatedValues.removeValue(forKey: fieldNumber)
      }
    }
    else if case .message = field.type {
      nestedMessages.removeValue(forKey: fieldNumber)
    }
    else {
      values.removeValue(forKey: fieldNumber)
    }

    // Обновляем состояние oneof полей
    if let oneofIndex = field.oneofIndex, activeOneofFields[oneofIndex] == fieldNumber {
      activeOneofFields.removeValue(forKey: oneofIndex)
    }

    return self
  }

  // MARK: - Repeated Field Methods

  /// Добавляет элемент в repeated поле.
  ///
  /// - Parameters:.
  ///   - value: Значение для добавления.
  ///   - fieldName: Имя поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует, не является repeated, или тип не соответствует.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try addRepeatedValue(value, forField: field.number)
  }

  /// Добавляет элемент в repeated поле.
  ///
  /// - Parameters:.
  ///   - value: Значение для добавления.
  ///   - fieldNumber: Номер поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует, не является repeated, или тип не соответствует.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    guard field.isRepeated && !field.isMap else {
      throw DynamicMessageError.notRepeatedField(fieldName: field.name)
    }

    // Проверяем тип значения
    try validateValue(value, for: field)

    // Преобразуем значение если нужно
    let convertedValue = convertToCorrectType(value, for: field)

    // Добавляем в массив
    var currentValues = repeatedValues[fieldNumber] ?? []
    currentValues.append(convertedValue)
    repeatedValues[fieldNumber] = currentValues

    return self
  }

  // MARK: - Map Field Methods

  /// Устанавливает запись в map поле.
  ///
  /// - Parameters:.
  ///   - value: Значение для установки.
  ///   - key: Ключ.
  ///   - fieldName: Имя поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует, не является map, или типы не соответствуют.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try setMapEntry(value, forKey: key, inField: field.number)
  }

  /// Устанавливает запись в map поле.
  ///
  /// - Parameters:.
  ///   - value: Значение для установки.
  ///   - key: Ключ.
  ///   - fieldNumber: Номер поля.
  /// - Returns: Обновленное сообщение.
  /// - Throws: Ошибку, если поле не существует, не является map, или типы не соответствуют.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    guard field.isMap, let mapInfo = field.mapEntryInfo else {
      throw DynamicMessageError.notMapField(fieldName: field.name)
    }

    // Проверяем тип ключа
    try validateMapKey(key, for: mapInfo.keyFieldInfo)

    // Проверяем тип значения
    try validateMapValue(value, for: mapInfo.valueFieldInfo)

    // Конвертируем ключ и значение в правильные типы
    let convertedKey = convertMapKey(key, for: mapInfo.keyFieldInfo)
    let convertedValue = convertMapValue(value, for: mapInfo.valueFieldInfo)

    // Добавляем в map
    var currentMap = mapValues[fieldNumber] ?? [:]
    currentMap[convertedKey] = convertedValue
    mapValues[fieldNumber] = currentMap

    return self
  }

  // MARK: - Private Helper Methods

  /// Очищает значение oneof поля по его номеру.
  ///
  /// Используется для правильной очистки всех типов полей при переключении oneof.
  ///
  /// - Parameter fieldNumber: Номер поля для очистки.
  private mutating func clearOneofField(_ fieldNumber: Int) {
    guard let field = descriptor.field(number: fieldNumber) else {
      return  // Поле не найдено, ничего не делаем
    }

    // Очищаем значение из соответствующего хранилища в зависимости от типа поля
    if field.isRepeated {
      if field.isMap {
        mapValues.removeValue(forKey: fieldNumber)
      }
      else {
        repeatedValues.removeValue(forKey: fieldNumber)
      }
    }
    else if case .message = field.type {
      nestedMessages.removeValue(forKey: fieldNumber)
    }
    else {
      values.removeValue(forKey: fieldNumber)
    }
  }

  // MARK: - Validation Methods

  /// Проверяет, соответствует ли значение требуемому типу поля.
  ///
  /// - Parameters:.
  ///   - value: Проверяемое значение.
  ///   - field: Дескриптор поля.
  ///   - itemIndex: Индекс элемента в массиве (для repeated полей).
  /// - Throws: Ошибку, если тип не соответствует.
  private func validateValue(_ value: Any, for field: FieldDescriptor, itemIndex: Int? = nil) throws {
    let indexSuffix = itemIndex != nil ? " at index \(itemIndex!)" : ""
    let fieldDesc = "\(field.name)\(indexSuffix)"

    switch field.type {
    case .double:
      guard value is Double || value is NSNumber else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Double",
          actualValue: value
        )
      }
    case .float:
      guard value is Float || value is NSNumber else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Float",
          actualValue: value
        )
      }
    case .int32, .sint32, .sfixed32:
      guard value is Int32 || (value is Int && (value as! Int) >= Int32.min && (value as! Int) <= Int32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Int32",
          actualValue: value
        )
      }
    case .int64, .sint64, .sfixed64:
      guard value is Int64 || value is Int else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Int64",
          actualValue: value
        )
      }
    case .uint32, .fixed32:
      guard value is UInt32 || (value is UInt && (value as! UInt) <= UInt32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "UInt32",
          actualValue: value
        )
      }
    case .uint64, .fixed64:
      guard value is UInt64 || value is UInt else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "UInt64",
          actualValue: value
        )
      }
    case .bool:
      guard value is Bool else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Bool",
          actualValue: value
        )
      }
    case .string:
      guard value is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "String",
          actualValue: value
        )
      }
    case .bytes:
      guard value is Data else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Data",
          actualValue: value
        )
      }
    case .message:
      guard value is DynamicMessage else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "DynamicMessage",
          actualValue: value
        )
      }

      // Проверяем, соответствует ли тип сообщения ожидаемому
      let message = value as! DynamicMessage
      let expectedTypeName = field.typeName ?? ""
      let actualTypeName = message.descriptor.fullName

      guard expectedTypeName == actualTypeName else {
        throw DynamicMessageError.messageMismatch(
          fieldName: fieldDesc,
          expectedType: expectedTypeName,
          actualType: actualTypeName
        )
      }
    case .enum:
      // Для перечислений мы ожидаем либо Int32 (номер), либо String (имя)
      guard value is Int32 || value is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Enum (Int32 or String)",
          actualValue: value
        )
      }

    // TODO: Полная проверка значений enum при наличии реестра типов
    case .group:
      // Group - устаревший тип, поддерживаем для совместимости с proto2
      guard value is DynamicMessage else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "DynamicMessage (group)",
          actualValue: value
        )
      }
    }
  }

  /// Проверяет правильность значений в map.
  ///
  /// - Parameters:.
  ///   - mapValue: Map для проверки.
  ///   - field: Дескриптор поля.
  /// - Throws: Ошибку, если тип ключа или значения не соответствует.
  private func validateMapValues(_ mapValue: [AnyHashable: Any], for field: FieldDescriptor) throws {
    guard let mapInfo = field.mapEntryInfo else {
      throw DynamicMessageError.notMapField(fieldName: field.name)
    }

    // Проверяем все ключи и значения
    for (key, value) in mapValue {
      try validateMapKey(key, for: mapInfo.keyFieldInfo)
      try validateMapValue(value, for: mapInfo.valueFieldInfo)
    }
  }

  /// Проверяет правильность ключа в map.
  ///
  /// - Parameters:.
  ///   - key: Ключ для проверки.
  ///   - keyFieldInfo: Информация о поле ключа.
  /// - Throws: Ошибку, если тип ключа не соответствует.
  private func validateMapKey(_ key: AnyHashable, for keyFieldInfo: KeyFieldInfo) throws {
    switch keyFieldInfo.type {
    case .int32, .sint32, .sfixed32:
      guard key is Int32 || (key is Int && (key as! Int) >= Int32.min && (key as! Int) <= Int32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Int32",
          actualValue: key
        )
      }
    case .int64, .sint64, .sfixed64:
      guard key is Int64 || key is Int else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Int64",
          actualValue: key
        )
      }
    case .uint32, .fixed32:
      guard key is UInt32 || (key is UInt && (key as! UInt) <= UInt32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "UInt32",
          actualValue: key
        )
      }
    case .uint64, .fixed64:
      guard key is UInt64 || key is UInt else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "UInt64",
          actualValue: key
        )
      }
    case .bool:
      guard key is Bool else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Bool",
          actualValue: key
        )
      }
    case .string:
      guard key is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "String",
          actualValue: key
        )
      }
    default:
      // Другие типы недопустимы для ключей map
      throw DynamicMessageError.invalidMapKeyType(type: keyFieldInfo.type)
    }
  }

  /// Проверяет правильность значения в map.
  ///
  /// - Parameters:.
  ///   - value: Значение для проверки.
  ///   - valueFieldInfo: Информация о поле значения.
  /// - Throws: Ошибку, если тип значения не соответствует.
  private func validateMapValue(_ value: Any, for valueFieldInfo: ValueFieldInfo) throws {
    // Создаем временный дескриптор поля для переиспользования проверки
    let tempField = FieldDescriptor(
      name: "value",
      number: valueFieldInfo.number,
      type: valueFieldInfo.type,
      typeName: valueFieldInfo.typeName
    )

    try validateValue(value, for: tempField)
  }

  /// Конвертирует значение в правильный тип для сохранения, если требуется.
  ///
  /// - Parameters:.
  ///   - value: Исходное значение.
  ///   - field: Дескриптор поля.
  /// - Returns: Преобразованное значение, подходящее для сохранения.
  private func convertToCorrectType(_ value: Any, for field: FieldDescriptor) -> Any {
    switch field.type {
    case .int32, .sint32, .sfixed32:
      if let intValue = value as? Int {
        return Int32(intValue)
      }
    case .int64, .sint64, .sfixed64:
      if let intValue = value as? Int {
        return Int64(intValue)
      }
    case .uint32, .fixed32:
      if let uintValue = value as? UInt {
        return UInt32(uintValue)
      }
    case .uint64, .fixed64:
      if let uintValue = value as? UInt {
        return UInt64(uintValue)
      }
    case .float:
      if let number = value as? NSNumber, !(value is Float) {
        return number.floatValue
      }
    case .double:
      if let number = value as? NSNumber, !(value is Double) {
        return number.doubleValue
      }
    default:
      break
    }
    return value
  }

  /// Преобразует ключ map в правильный тип.
  private func convertMapKey(_ key: AnyHashable, for keyFieldInfo: KeyFieldInfo) -> AnyHashable {
    switch keyFieldInfo.type {
    case .int32, .sint32, .sfixed32:
      if let intValue = key as? Int {
        return Int32(intValue) as AnyHashable
      }
    case .int64, .sint64, .sfixed64:
      if let intValue = key as? Int {
        return Int64(intValue) as AnyHashable
      }
    case .uint32, .fixed32:
      if let uintValue = key as? UInt {
        return UInt32(uintValue) as AnyHashable
      }
    case .uint64, .fixed64:
      if let uintValue = key as? UInt {
        return UInt64(uintValue) as AnyHashable
      }
    default:
      break
    }
    return key
  }

  /// Преобразует значение map в правильный тип.
  private func convertMapValue(_ value: Any, for valueFieldInfo: ValueFieldInfo) -> Any {
    // Создаем временный дескриптор поля для переиспользования проверки
    let tempField = FieldDescriptor(
      name: "value",
      number: valueFieldInfo.number,
      type: valueFieldInfo.type,
      typeName: valueFieldInfo.typeName
    )

    return convertToCorrectType(value, for: tempField)
  }

  // MARK: - Equatable

  public static func == (lhs: DynamicMessage, rhs: DynamicMessage) -> Bool {
    // Сравниваем по дескриптору и значениям полей
    guard lhs.descriptor.fullName == rhs.descriptor.fullName else {
      return false
    }

    // Получаем все поля дескриптора
    let allFields = lhs.descriptor.allFields()

    for field in allFields {
      let fieldNumber = field.number

      do {
        let lhsHasValue = try lhs.hasValue(forField: fieldNumber)
        let rhsHasValue = try rhs.hasValue(forField: fieldNumber)

        // Если наличие значения различается, сообщения не равны
        if lhsHasValue != rhsHasValue {
          return false
        }

        // Если оба не имеют значения, переходим к следующему полю
        if !lhsHasValue && !rhsHasValue {
          continue
        }

        // Получаем значения
        let lhsValue = try lhs.get(forField: fieldNumber)
        let rhsValue = try rhs.get(forField: fieldNumber)

        // Сравниваем значения в зависимости от типа поля
        if field.isRepeated {
          if field.isMap {
            // Сравниваем map
            let lhsMap = lhsValue as? [AnyHashable: Any]
            let rhsMap = rhsValue as? [AnyHashable: Any]

            guard let lm = lhsMap, let rm = rhsMap, lm.count == rm.count else {
              return false
            }

            // Сравниваем ключи
            let lhsKeys = Set(lm.keys.map { String(describing: $0) })
            let rhsKeys = Set(rm.keys.map { String(describing: $0) })

            if lhsKeys != rhsKeys {
              return false
            }

            // Сравниваем значения для каждого ключа
            for (key, lhsMapValue) in lm {
              guard let rhsMapValue = rm[key] else {
                return false
              }

              if !areValuesEqual(lhsMapValue, rhsMapValue, fieldType: field.mapEntryInfo?.valueFieldInfo.type) {
                return false
              }
            }
          }
          else {
            // Сравниваем repeated
            let lhsArray = lhsValue as? [Any]
            let rhsArray = rhsValue as? [Any]

            guard let la = lhsArray, let ra = rhsArray, la.count == ra.count else {
              return false
            }

            // Сравниваем каждый элемент
            for i in 0..<la.count where !areValuesEqual(la[i], ra[i], fieldType: field.type) {
              return false
            }
          }
        }
        else {
          // Сравниваем обычные поля
          if !areValuesEqual(lhsValue!, rhsValue!, fieldType: field.type) {
            return false
          }
        }
      }
      catch {
        // При ошибке доступа к полю считаем, что сообщения не равны
        return false
      }
    }

    return true
  }

  /// Сравнивает два значения на равенство с учетом типа поля.
  ///
  /// - Parameters:.
  ///   - lhs: Первое значение.
  ///   - rhs: Второе значение.
  ///   - fieldType: Тип поля.
  /// - Returns: true, если значения равны.
  private static func areValuesEqual(_ lhs: Any, _ rhs: Any, fieldType: FieldType?) -> Bool {
    switch fieldType {
    case .double:
      return (lhs as? Double) == (rhs as? Double)
    case .float:
      return (lhs as? Float) == (rhs as? Float)
    case .int32, .sint32, .sfixed32:
      return (lhs as? Int32) == (rhs as? Int32)
    case .int64, .sint64, .sfixed64:
      return (lhs as? Int64) == (rhs as? Int64)
    case .uint32, .fixed32:
      return (lhs as? UInt32) == (rhs as? UInt32)
    case .uint64, .fixed64:
      return (lhs as? UInt64) == (rhs as? UInt64)
    case .bool:
      return (lhs as? Bool) == (rhs as? Bool)
    case .string:
      return (lhs as? String) == (rhs as? String)
    case .bytes:
      return (lhs as? Data) == (rhs as? Data)
    case .enum:
      // Для enum сравниваем либо номера, либо строки
      if let lhsInt = lhs as? Int32, let rhsInt = rhs as? Int32 {
        return lhsInt == rhsInt
      }
      else if let lhsStr = lhs as? String, let rhsStr = rhs as? String {
        return lhsStr == rhsStr
      }
      else {
        return false
      }
    case .message, .group:
      // Для сообщений сравниваем по встроенному Equatable
      return (lhs as? DynamicMessage) == (rhs as? DynamicMessage)
    default:
      // Для других типов используем общее описание
      return String(describing: lhs) == String(describing: rhs)
    }
  }
}

/// Ошибки, возникающие при работе с динамическими сообщениями.
public enum DynamicMessageError: Error, LocalizedError {
  case fieldNotFound(fieldName: String)
  case fieldNotFoundByNumber(fieldNumber: Int)
  case typeMismatch(fieldName: String, expectedType: String, actualValue: Any)
  case messageMismatch(fieldName: String, expectedType: String, actualType: String)
  case notRepeatedField(fieldName: String)
  case notMapField(fieldName: String)
  case invalidMapKeyType(type: FieldType)

  public var errorDescription: String? {
    switch self {
    case .fieldNotFound(let fieldName):
      return "Поле с именем '\(fieldName)' не найдено"
    case .fieldNotFoundByNumber(let fieldNumber):
      return "Поле с номером \(fieldNumber) не найдено"
    case .typeMismatch(let fieldName, let expectedType, let actualValue):
      return "Несоответствие типа для поля '\(fieldName)': ожидается \(expectedType), получено \(type(of: actualValue))"
    case .messageMismatch(let fieldName, let expectedType, let actualType):
      return "Несоответствие типа сообщения для поля '\(fieldName)': ожидается \(expectedType), получено \(actualType)"
    case .notRepeatedField(let fieldName):
      return "Поле '\(fieldName)' не является repeated полем"
    case .notMapField(let fieldName):
      return "Поле '\(fieldName)' не является map полем"
    case .invalidMapKeyType(let type):
      return "Недопустимый тип ключа \(type) для map поля"
    }
  }
}
