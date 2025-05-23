//
// EnumDescriptor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-22
//

import Foundation
import SwiftProtobuf

/// EnumDescriptor.
///
/// Дескриптор перечисления Protocol Buffers, который описывает.
/// значения перечисления, их имена, числовые значения и опции.
public struct EnumDescriptor: Equatable {
  // MARK: - Types

  /// Значение перечисления с его именем и опциями.
  public struct EnumValue: Equatable {
    /// Имя значения перечисления (например, "UNKNOWN").
    public let name: String

    /// Числовое значение элемента перечисления.
    public let number: Int

    /// Опции значения перечисления.
    public let options: [String: Any]

    /// Создает новое значение перечисления.
    ///
    /// - Parameters:.
    ///   - name: Имя значения перечисления.
    ///   - number: Числовое значение.
    ///   - options: Опции значения перечисления.
    public init(name: String, number: Int, options: [String: Any] = [:]) {
      self.name = name
      self.number = number
      self.options = options
    }

    // MARK: - Equatable

    public static func == (lhs: EnumValue, rhs: EnumValue) -> Bool {
      guard lhs.name == rhs.name && lhs.number == rhs.number else {
        return false
      }

      // Сравниваем options: проверяем ключи и значения
      let lhsKeys = Set(lhs.options.keys)
      let rhsKeys = Set(rhs.options.keys)

      guard lhsKeys == rhsKeys else {
        return false
      }

      // Проверяем совпадение значений для всех ключей
      for key in lhsKeys {
        let lhsValue = lhs.options[key]
        let rhsValue = rhs.options[key]

        // Проверяем известные типы значений
        if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
          if lhsBool != rhsBool {
            return false
          }
        }
        else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
          if lhsInt != rhsInt {
            return false
          }
        }
        else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
          if lhsString != rhsString {
            return false
          }
        }
        else {
          // Для других типов, сравниваем строковые представления
          if String(describing: lhsValue) != String(describing: rhsValue) {
            return false
          }
        }
      }

      return true
    }
  }

  // MARK: - Properties

  /// Имя перечисления (например, "Status").
  public let name: String

  /// Полное имя перечисления, включая пакет (например, "example.Status").
  public let fullName: String

  /// Путь к родительскому файлу (для разрешения ссылок).
  public var fileDescriptorPath: String?

  /// Полное имя родительского сообщения (если это вложенное перечисление).
  public var parentMessageFullName: String?

  /// Список значений перечисления по имени.
  public private(set) var valuesByName: [String: EnumValue] = [:]

  /// Список значений перечисления по числовому значению.
  public private(set) var valuesByNumber: [Int: EnumValue] = [:]

  /// Опции перечисления.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Создает новый экземпляр EnumDescriptor.
  ///
  /// - Parameters:.
  ///   - name: Имя перечисления.
  ///   - fullName: Полное имя перечисления.
  ///   - options: Опции перечисления.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Создает новый экземпляр EnumDescriptor с базовым именем.
  ///
  /// Полное имя будет сгенерировано автоматически на основе родительского файла или сообщения.
  ///
  /// - Parameters:.
  ///   - name: Имя перечисления.
  ///   - parent: Родительский файл или сообщение.
  ///   - options: Опции перечисления.
  public init(
    name: String,
    parent: Any? = nil,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.options = options

    if let parentMessage = parent as? MessageDescriptor {
      self.fullName = "\(parentMessage.fullName).\(name)"
      self.parentMessageFullName = parentMessage.fullName
      self.fileDescriptorPath = parentMessage.fileDescriptorPath
    }
    else if let fileDescriptor = parent as? FileDescriptor {
      self.fullName = fileDescriptor.getFullName(for: name)
      self.fileDescriptorPath = fileDescriptor.name
    }
    else {
      self.fullName = name
    }
  }

  // MARK: - Value Methods

  /// Добавляет значение перечисления.
  ///
  /// - Parameter value: Значение перечисления для добавления.
  /// - Returns: Обновленный EnumDescriptor.
  @discardableResult
  public mutating func addValue(_ value: EnumValue) -> Self {
    valuesByName[value.name] = value
    valuesByNumber[value.number] = value
    return self
  }

  /// Проверяет, содержит ли перечисление указанное значение по имени.
  ///
  /// - Parameter name: Имя значения.
  /// - Returns: true, если значение существует.
  public func hasValue(named name: String) -> Bool {
    return valuesByName[name] != nil
  }

  /// Проверяет, содержит ли перечисление указанное значение по числу.
  ///
  /// - Parameter number: Числовое значение.
  /// - Returns: true, если значение существует.
  public func hasValue(number: Int) -> Bool {
    return valuesByNumber[number] != nil
  }

  /// Получает значение перечисления по имени.
  ///
  /// - Parameter name: Имя значения.
  /// - Returns: Значение перечисления, если оно существует.
  public func value(named name: String) -> EnumValue? {
    return valuesByName[name]
  }

  /// Получает значение перечисления по числовому значению.
  ///
  /// - Parameter number: Числовое значение.
  /// - Returns: Значение перечисления, если оно существует.
  public func value(number: Int) -> EnumValue? {
    return valuesByNumber[number]
  }

  /// Получает список всех значений перечисления, упорядоченных по числовому значению.
  ///
  /// - Returns: Упорядоченный список значений перечисления.
  public func allValues() -> [EnumValue] {
    return valuesByNumber.sorted { $0.key < $1.key }.map { $0.value }
  }

  // MARK: - Equatable

  public static func == (lhs: EnumDescriptor, rhs: EnumDescriptor) -> Bool {
    // Сравниваем основные свойства
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.parentMessageFullName == rhs.parentMessageFullName
    else {
      return false
    }

    // Сравниваем значения перечисления
    let lhsValuesByName = lhs.valuesByName
    let rhsValuesByName = rhs.valuesByName

    guard lhsValuesByName.count == rhsValuesByName.count else {
      return false
    }

    for (name, lhsValue) in lhsValuesByName {
      guard let rhsValue = rhsValuesByName[name], lhsValue == rhsValue else {
        return false
      }
    }

    // Сравниваем опции
    let lhsKeys = Set(lhs.options.keys)
    let rhsKeys = Set(rhs.options.keys)

    guard lhsKeys == rhsKeys else {
      return false
    }

    // Проверяем совпадение значений для всех ключей
    for key in lhsKeys {
      let lhsValue = lhs.options[key]
      let rhsValue = rhs.options[key]

      // Проверяем известные типы значений
      if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
        if lhsBool != rhsBool {
          return false
        }
      }
      else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
        if lhsInt != rhsInt {
          return false
        }
      }
      else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
        if lhsString != rhsString {
          return false
        }
      }
      else {
        // Для других типов, сравниваем строковые представления
        if String(describing: lhsValue) != String(describing: rhsValue) {
          return false
        }
      }
    }

    return true
  }
}
