//
// MessageDescriptor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-18
//

import Foundation
import SwiftProtobuf

/// MessageDescriptor.
///
/// Дескриптор сообщения Protocol Buffers, который описывает.
/// структуру сообщения, его поля, вложенные типы и опции.
public struct MessageDescriptor {
  // MARK: - Properties

  /// Имя сообщения (например, "Person").
  public let name: String

  /// Полное имя сообщения, включая пакет (например, "example.person.Person").
  public let fullName: String

  /// Путь к родительскому файлу (для разрешения ссылок).
  public var fileDescriptorPath: String?

  /// Полное имя родительского сообщения (если это вложенное сообщение).
  public var parentMessageFullName: String?

  /// Список полей сообщения.
  public private(set) var fields: [Int: FieldDescriptor] = [:]

  /// Список полей сообщения по имени.
  public private(set) var fieldsByName: [String: FieldDescriptor] = [:]

  /// Список вложенных сообщений.
  public private(set) var nestedMessages: [String: MessageDescriptor] = [:]

  /// Список вложенных перечислений.
  public private(set) var nestedEnums: [String: EnumDescriptor] = [:]

  /// Опции сообщения.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Создает новый экземпляр MessageDescriptor.
  ///
  /// - Parameters:.
  ///   - name: Имя сообщения.
  ///   - fullName: Полное имя сообщения.
  ///   - options: Опции сообщения.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Создает новый экземпляр MessageDescriptor с базовым именем.
  ///
  /// Полное имя будет сгенерировано автоматически на основе родительского файла или сообщения.
  ///
  /// - Parameters:.
  ///   - name: Имя сообщения.
  ///   - parent: Родительский файл или сообщение.
  ///   - options: Опции сообщения.
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

  // MARK: - Field Methods

  /// Добавляет поле в сообщение.
  ///
  /// - Parameter field: Дескриптор поля для добавления.
  /// - Returns: Обновленный MessageDescriptor.
  @discardableResult
  public mutating func addField(_ field: FieldDescriptor) -> Self {
    fields[field.number] = field
    fieldsByName[field.name] = field
    return self
  }

  /// Проверяет, содержит ли сообщение указанное поле.
  ///
  /// - Parameter number: Номер поля.
  /// - Returns: true, если поле существует.
  public func hasField(number: Int) -> Bool {
    return fields[number] != nil
  }

  /// Проверяет, содержит ли сообщение указанное поле.
  ///
  /// - Parameter name: Имя поля.
  /// - Returns: true, если поле существует.
  public func hasField(named name: String) -> Bool {
    return fieldsByName[name] != nil
  }

  /// Получает поле по номеру.
  ///
  /// - Parameter number: Номер поля.
  /// - Returns: Дескриптор поля, если он существует.
  public func field(number: Int) -> FieldDescriptor? {
    return fields[number]
  }

  /// Получает поле по имени.
  ///
  /// - Parameter name: Имя поля.
  /// - Returns: Дескриптор поля, если он существует.
  public func field(named name: String) -> FieldDescriptor? {
    return fieldsByName[name]
  }

  /// Получает список всех полей, упорядоченных по номеру.
  ///
  /// - Returns: Упорядоченный список полей.
  public func allFields() -> [FieldDescriptor] {
    return fields.sorted { $0.key < $1.key }.map { $0.value }
  }

  // MARK: - Nested Type Methods

  /// Добавляет вложенное сообщение.
  ///
  /// - Parameter message: Дескриптор вложенного сообщения.
  /// - Returns: Обновленный MessageDescriptor.
  @discardableResult
  public mutating func addNestedMessage(_ message: MessageDescriptor) -> Self {
    var messageCopy = message
    messageCopy.parentMessageFullName = self.fullName
    messageCopy.fileDescriptorPath = self.fileDescriptorPath
    nestedMessages[message.name] = messageCopy
    return self
  }

  /// Добавляет вложенное перечисление.
  ///
  /// - Parameter enumDescriptor: Дескриптор вложенного перечисления.
  /// - Returns: Обновленный MessageDescriptor.
  @discardableResult
  public mutating func addNestedEnum(_ enumDescriptor: EnumDescriptor) -> Self {
    nestedEnums[enumDescriptor.name] = enumDescriptor
    return self
  }

  /// Проверяет, содержит ли сообщение указанное вложенное сообщение.
  ///
  /// - Parameter name: Имя вложенного сообщения.
  /// - Returns: true, если вложенное сообщение существует.
  public func hasNestedMessage(named name: String) -> Bool {
    return nestedMessages[name] != nil
  }

  /// Проверяет, содержит ли сообщение указанное вложенное перечисление.
  ///
  /// - Parameter name: Имя вложенного перечисления.
  /// - Returns: true, если вложенное перечисление существует.
  public func hasNestedEnum(named name: String) -> Bool {
    return nestedEnums[name] != nil
  }

  /// Получает вложенное сообщение по имени.
  ///
  /// - Parameter name: Имя вложенного сообщения.
  /// - Returns: Дескриптор вложенного сообщения, если он существует.
  public func nestedMessage(named name: String) -> MessageDescriptor? {
    return nestedMessages[name]
  }

  /// Получает вложенное перечисление по имени.
  ///
  /// - Parameter name: Имя вложенного перечисления.
  /// - Returns: Дескриптор вложенного перечисления, если он существует.
  public func nestedEnum(named name: String) -> EnumDescriptor? {
    return nestedEnums[name]
  }
}

// FieldDescriptor определен в файле FieldDescriptor.swift
