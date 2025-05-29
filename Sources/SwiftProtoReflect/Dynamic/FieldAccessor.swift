//
// FieldAccessor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// FieldAccessor.
///
/// Предоставляет типобезопасный и удобный интерфейс для доступа к полям.
/// динамических Protocol Buffers сообщений. Упрощает получение и установку
/// значений полей с минимальной обработкой ошибок и максимальной типобезопасностью.
public struct FieldAccessor {
  // MARK: - Properties

  /// Целевое сообщение для доступа к полям.
  private let message: DynamicMessage

  // MARK: - Initialization

  /// Создает новый экземпляр FieldAccessor для заданного сообщения.
  ///
  /// - Parameter message: Динамическое сообщение для доступа к полям.
  public init(_ message: DynamicMessage) {
    self.message = message
  }

  // MARK: - Typed Field Access Methods

  /// Безопасно получает строковое значение поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Строковое значение или nil, если поле не установлено или имеет другой тип.
  public func getString(_ fieldName: String) -> String? {
    return getValue(fieldName, as: String.self)
  }

  /// Безопасно получает строковое значение поля по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Строковое значение или nil, если поле не установлено или имеет другой тип.
  public func getString(_ fieldNumber: Int) -> String? {
    return getValue(fieldNumber, as: String.self)
  }

  /// Безопасно получает целочисленное значение поля (Int32).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getInt32(_ fieldName: String) -> Int32? {
    return getValue(fieldName, as: Int32.self)
  }

  /// Безопасно получает целочисленное значение поля (Int32) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getInt32(_ fieldNumber: Int) -> Int32? {
    return getValue(fieldNumber, as: Int32.self)
  }

  /// Безопасно получает целочисленное значение поля (Int64).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getInt64(_ fieldName: String) -> Int64? {
    return getValue(fieldName, as: Int64.self)
  }

  /// Безопасно получает целочисленное значение поля (Int64) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getInt64(_ fieldNumber: Int) -> Int64? {
    return getValue(fieldNumber, as: Int64.self)
  }

  /// Безопасно получает беззнаковое целочисленное значение поля (UInt32).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Беззнаковое целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getUInt32(_ fieldName: String) -> UInt32? {
    return getValue(fieldName, as: UInt32.self)
  }

  /// Безопасно получает беззнаковое целочисленное значение поля (UInt32) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Беззнаковое целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getUInt32(_ fieldNumber: Int) -> UInt32? {
    return getValue(fieldNumber, as: UInt32.self)
  }

  /// Безопасно получает беззнаковое целочисленное значение поля (UInt64).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Беззнаковое целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getUInt64(_ fieldName: String) -> UInt64? {
    return getValue(fieldName, as: UInt64.self)
  }

  /// Безопасно получает беззнаковое целочисленное значение поля (UInt64) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Беззнаковое целочисленное значение или nil, если поле не установлено или имеет другой тип.
  public func getUInt64(_ fieldNumber: Int) -> UInt64? {
    return getValue(fieldNumber, as: UInt64.self)
  }

  /// Безопасно получает значение с плавающей точкой поля (Float).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Значение с плавающей точкой или nil, если поле не установлено или имеет другой тип.
  public func getFloat(_ fieldName: String) -> Float? {
    return getValue(fieldName, as: Float.self)
  }

  /// Безопасно получает значение с плавающей точкой поля (Float) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Значение с плавающей точкой или nil, если поле не установлено или имеет другой тип.
  public func getFloat(_ fieldNumber: Int) -> Float? {
    return getValue(fieldNumber, as: Float.self)
  }

  /// Безопасно получает значение с плавающей точкой поля (Double).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Значение с плавающей точкой или nil, если поле не установлено или имеет другой тип.
  public func getDouble(_ fieldName: String) -> Double? {
    return getValue(fieldName, as: Double.self)
  }

  /// Безопасно получает значение с плавающей точкой поля (Double) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Значение с плавающей точкой или nil, если поле не установлено или имеет другой тип.
  public func getDouble(_ fieldNumber: Int) -> Double? {
    return getValue(fieldNumber, as: Double.self)
  }

  /// Безопасно получает булево значение поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Булево значение или nil, если поле не установлено или имеет другой тип.
  public func getBool(_ fieldName: String) -> Bool? {
    return getValue(fieldName, as: Bool.self)
  }

  /// Безопасно получает булево значение поля по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Булево значение или nil, если поле не установлено или имеет другой тип.
  public func getBool(_ fieldNumber: Int) -> Bool? {
    return getValue(fieldNumber, as: Bool.self)
  }

  /// Безопасно получает данные поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Данные или nil, если поле не установлено или имеет другой тип.
  public func getData(_ fieldName: String) -> Data? {
    return getValue(fieldName, as: Data.self)
  }

  /// Безопасно получает данные поля по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Данные или nil, если поле не установлено или имеет другой тип.
  public func getData(_ fieldNumber: Int) -> Data? {
    return getValue(fieldNumber, as: Data.self)
  }

  /// Безопасно получает вложенное сообщение поля.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Динамическое сообщение или nil, если поле не установлено или имеет другой тип.
  public func getMessage(_ fieldName: String) -> DynamicMessage? {
    return getValue(fieldName, as: DynamicMessage.self)
  }

  /// Безопасно получает вложенное сообщение поля по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Динамическое сообщение или nil, если поле не установлено или имеет другой тип.
  public func getMessage(_ fieldNumber: Int) -> DynamicMessage? {
    return getValue(fieldNumber, as: DynamicMessage.self)
  }

  // MARK: - Repeated Field Access Methods

  /// Безопасно получает repeated строковое поле.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Массив строк или nil, если поле не установлено или имеет другой тип.
  public func getStringArray(_ fieldName: String) -> [String]? {
    return getRepeatedValue(fieldName, as: String.self)
  }

  /// Безопасно получает repeated строковое поле по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Массив строк или nil, если поле не установлено или имеет другой тип.
  public func getStringArray(_ fieldNumber: Int) -> [String]? {
    return getRepeatedValue(fieldNumber, as: String.self)
  }

  /// Безопасно получает repeated поле целых чисел (Int32).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Массив целых чисел или nil, если поле не установлено или имеет другой тип.
  public func getInt32Array(_ fieldName: String) -> [Int32]? {
    return getRepeatedValue(fieldName, as: Int32.self)
  }

  /// Безопасно получает repeated поле целых чисел (Int32) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Массив целых чисел или nil, если поле не установлено или имеет другой тип.
  public func getInt32Array(_ fieldNumber: Int) -> [Int32]? {
    return getRepeatedValue(fieldNumber, as: Int32.self)
  }

  /// Безопасно получает repeated поле целых чисел (Int64).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Массив целых чисел или nil, если поле не установлено или имеет другой тип.
  public func getInt64Array(_ fieldName: String) -> [Int64]? {
    return getRepeatedValue(fieldName, as: Int64.self)
  }

  /// Безопасно получает repeated поле целых чисел (Int64) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Массив целых чисел или nil, если поле не установлено или имеет другой тип.
  public func getInt64Array(_ fieldNumber: Int) -> [Int64]? {
    return getRepeatedValue(fieldNumber, as: Int64.self)
  }

  /// Безопасно получает repeated поле вложенных сообщений.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Массив динамических сообщений или nil, если поле не установлено или имеет другой тип.
  public func getMessageArray(_ fieldName: String) -> [DynamicMessage]? {
    return getRepeatedValue(fieldName, as: DynamicMessage.self)
  }

  /// Безопасно получает repeated поле вложенных сообщений по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Массив динамических сообщений или nil, если поле не установлено или имеет другой тип.
  public func getMessageArray(_ fieldNumber: Int) -> [DynamicMessage]? {
    return getRepeatedValue(fieldNumber, as: DynamicMessage.self)
  }

  // MARK: - Map Field Access Methods

  /// Безопасно получает map поле с строковыми ключами и значениями.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Словарь строк или nil, если поле не установлено или имеет другой тип.
  public func getStringMap(_ fieldName: String) -> [String: String]? {
    return getMapValue(fieldName, keyType: String.self, valueType: String.self)
  }

  /// Безопасно получает map поле с строковыми ключами и значениями по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Словарь строк или nil, если поле не установлено или имеет другой тип.
  public func getStringMap(_ fieldNumber: Int) -> [String: String]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: String.self)
  }

  /// Безопасно получает map поле с строковыми ключами и числовыми значениями (Int32).
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Словарь с числовыми значениями или nil, если поле не установлено или имеет другой тип.
  public func getStringToInt32Map(_ fieldName: String) -> [String: Int32]? {
    return getMapValue(fieldName, keyType: String.self, valueType: Int32.self)
  }

  /// Безопасно получает map поле с строковыми ключами и числовыми значениями (Int32) по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Словарь с числовыми значениями или nil, если поле не установлено или имеет другой тип.
  public func getStringToInt32Map(_ fieldNumber: Int) -> [String: Int32]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: Int32.self)
  }

  /// Безопасно получает map поле с строковыми ключами и сообщениями в качестве значений.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Словарь с сообщениями или nil, если поле не установлено или имеет другой тип.
  public func getStringToMessageMap(_ fieldName: String) -> [String: DynamicMessage]? {
    return getMapValue(fieldName, keyType: String.self, valueType: DynamicMessage.self)
  }

  /// Безопасно получает map поле с строковыми ключами и сообщениями в качестве значений по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Словарь с сообщениями или nil, если поле не установлено или имеет другой тип.
  public func getStringToMessageMap(_ fieldNumber: Int) -> [String: DynamicMessage]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: DynamicMessage.self)
  }

  // MARK: - Field Existence and Safety Methods

  /// Проверяет, существует ли поле и установлено ли для него значение.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: true, если поле существует и имеет значение, false в противном случае.
  public func hasValue(_ fieldName: String) -> Bool {
    do {
      return try message.hasValue(forField: fieldName)
    }
    catch {
      return false
    }
  }

  /// Проверяет, существует ли поле и установлено ли для него значение по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: true, если поле существует и имеет значение, false в противном случае.
  public func hasValue(_ fieldNumber: Int) -> Bool {
    do {
      return try message.hasValue(forField: fieldNumber)
    }
    catch {
      return false
    }
  }

  /// Проверяет, существует ли поле в дескрипторе сообщения.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: true, если поле существует в дескрипторе.
  public func fieldExists(_ fieldName: String) -> Bool {
    return message.descriptor.field(named: fieldName) != nil
  }

  /// Проверяет, существует ли поле в дескрипторе сообщения по номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: true, если поле существует в дескрипторе.
  public func fieldExists(_ fieldNumber: Int) -> Bool {
    return message.descriptor.field(number: fieldNumber) != nil
  }

  /// Получает тип поля по его имени.
  ///
  /// - Parameter fieldName: Имя поля.
  /// - Returns: Тип поля или nil, если поле не существует.
  public func getFieldType(_ fieldName: String) -> FieldType? {
    return message.descriptor.field(named: fieldName)?.type
  }

  /// Получает тип поля по его номеру.
  ///
  /// - Parameter fieldNumber: Номер поля.
  /// - Returns: Тип поля или nil, если поле не существует.
  public func getFieldType(_ fieldNumber: Int) -> FieldType? {
    return message.descriptor.field(number: fieldNumber)?.type
  }

  // MARK: - Generic Field Access Methods

  /// Универсальный метод для безопасного получения значения поля с приведением к указанному типу.
  ///
  /// - Parameters:.
  ///   - fieldName: Имя поля.
  ///   - type: Тип, к которому нужно привести значение.
  /// - Returns: Значение указанного типа или nil, если поле не установлено или имеет другой тип.
  public func getValue<T>(_ fieldName: String, as type: T.Type) -> T? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      return value as? T
    }
    catch {
      return nil
    }
  }

  /// Универсальный метод для безопасного получения значения поля с приведением к указанному типу по номеру.
  ///
  /// - Parameters:.
  ///   - fieldNumber: Номер поля.
  ///   - type: Тип, к которому нужно привести значение.
  /// - Returns: Значение указанного типа или nil, если поле не установлено или имеет другой тип.
  public func getValue<T>(_ fieldNumber: Int, as type: T.Type) -> T? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      return value as? T
    }
    catch {
      return nil
    }
  }

  // MARK: - Private Helper Methods

  /// Безопасно получает repeated поле с элементами указанного типа.
  ///
  /// - Parameters:.
  ///   - fieldName: Имя поля.
  ///   - type: Тип элементов массива.
  /// - Returns: Массив элементов указанного типа или nil.
  private func getRepeatedValue<T>(_ fieldName: String, as type: T.Type) -> [T]? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      guard let array = value as? [Any] else {
        return nil
      }

      // Проверяем, что все элементы имеют правильный тип
      var result: [T] = []
      for item in array {
        guard let typedItem = item as? T else {
          return nil  // Если хотя бы один элемент не соответствует типу, возвращаем nil
        }
        result.append(typedItem)
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Безопасно получает repeated поле с элементами указанного типа по номеру.
  ///
  /// - Parameters:.
  ///   - fieldNumber: Номер поля.
  ///   - type: Тип элементов массива.
  /// - Returns: Массив элементов указанного типа или nil.
  private func getRepeatedValue<T>(_ fieldNumber: Int, as type: T.Type) -> [T]? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      guard let array = value as? [Any] else {
        return nil
      }

      // Проверяем, что все элементы имеют правильный тип
      var result: [T] = []
      for item in array {
        guard let typedItem = item as? T else {
          return nil  // Если хотя бы один элемент не соответствует типу, возвращаем nil
        }
        result.append(typedItem)
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Безопасно получает map поле с ключами и значениями указанных типов.
  ///
  /// - Parameters:.
  ///   - fieldName: Имя поля.
  ///   - keyType: Тип ключей.
  ///   - valueType: Тип значений.
  /// - Returns: Словарь с ключами и значениями указанных типов или nil.
  private func getMapValue<K: Hashable, V>(_ fieldName: String, keyType: K.Type, valueType: V.Type) -> [K: V]? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      guard let map = value as? [AnyHashable: Any] else {
        return nil
      }

      // Проверяем и конвертируем ключи и значения
      var result: [K: V] = [:]
      for (key, mapValue) in map {
        guard let typedKey = key as? K else {
          return nil  // Если хотя бы один ключ не соответствует типу, возвращаем nil
        }
        guard let typedValue = mapValue as? V else {
          return nil  // Если хотя бы одно значение не соответствует типу, возвращаем nil
        }
        result[typedKey] = typedValue
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Безопасно получает map поле с ключами и значениями указанных типов по номеру.
  ///
  /// - Parameters:.
  ///   - fieldNumber: Номер поля.
  ///   - keyType: Тип ключей.
  ///   - valueType: Тип значений.
  /// - Returns: Словарь с ключами и значениями указанных типов или nil.
  private func getMapValue<K: Hashable, V>(_ fieldNumber: Int, keyType: K.Type, valueType: V.Type) -> [K: V]? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      guard let map = value as? [AnyHashable: Any] else {
        return nil
      }

      // Проверяем и конвертируем ключи и значения
      var result: [K: V] = [:]
      for (key, mapValue) in map {
        guard let typedKey = key as? K else {
          return nil  // Если хотя бы один ключ не соответствует типу, возвращаем nil
        }
        guard let typedValue = mapValue as? V else {
          return nil  // Если хотя бы одно значение не соответствует типу, возвращаем nil
        }
        result[typedKey] = typedValue
      }

      return result
    }
    catch {
      return nil
    }
  }
}

// MARK: - Mutable Field Access

/// MutableFieldAccessor.
///
/// Расширение FieldAccessor для изменяемого доступа к полям динамических сообщений.
/// Позволяет безопасно устанавливать значения полей с минимальной обработкой ошибок.
public struct MutableFieldAccessor {
  // MARK: - Properties

  /// Целевое сообщение для изменения полей.
  private var message: DynamicMessage

  // MARK: - Initialization

  /// Создает новый экземпляр MutableFieldAccessor для заданного сообщения.
  ///
  /// - Parameter message: Динамическое сообщение для изменения полей.
  public init(_ message: inout DynamicMessage) {
    self.message = message
  }

  // MARK: - Field Setting Methods

  /// Безопасно устанавливает строковое значение поля.
  ///
  /// - Parameters:.
  ///   - value: Строковое значение для установки.
  ///   - fieldName: Имя поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает строковое значение поля по номеру.
  ///
  /// - Parameters:.
  ///   - value: Строковое значение для установки.
  ///   - fieldNumber: Номер поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает целочисленное значение поля (Int32).
  ///
  /// - Parameters:.
  ///   - value: Целочисленное значение для установки.
  ///   - fieldName: Имя поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает целочисленное значение поля (Int32) по номеру.
  ///
  /// - Parameters:.
  ///   - value: Целочисленное значение для установки.
  ///   - fieldNumber: Номер поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает булево значение поля.
  ///
  /// - Parameters:.
  ///   - value: Булево значение для установки.
  ///   - fieldName: Имя поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает булево значение поля по номеру.
  ///
  /// - Parameters:.
  ///   - value: Булево значение для установки.
  ///   - fieldNumber: Номер поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает вложенное сообщение поля.
  ///
  /// - Parameters:.
  ///   - value: Динамическое сообщение для установки.
  ///   - fieldName: Имя поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Безопасно устанавливает вложенное сообщение поля по номеру.
  ///
  /// - Parameters:.
  ///   - value: Динамическое сообщение для установки.
  ///   - fieldNumber: Номер поля.
  /// - Returns: true, если значение было успешно установлено, false в противном случае.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Возвращает обновленное сообщение.
  ///
  /// - Returns: Обновленное динамическое сообщение.
  public func updatedMessage() -> DynamicMessage {
    return message
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {
  /// Создает FieldAccessor для чтения полей этого сообщения.
  ///
  /// - Returns: FieldAccessor для безопасного чтения полей.
  public var fieldAccessor: FieldAccessor {
    return FieldAccessor(self)
  }

  /// Создает MutableFieldAccessor для изменения полей этого сообщения.
  ///
  /// - Returns: MutableFieldAccessor для безопасного изменения полей.
  public mutating func mutableFieldAccessor() -> MutableFieldAccessor {
    return MutableFieldAccessor(&self)
  }
}
