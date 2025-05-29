//
// DescriptorPool.swift
// SwiftProtoReflect
//
// Создан: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// DescriptorPool.
///
/// Контейнер для динамического создания и управления дескрипторами Protocol Buffers во время выполнения.
/// DescriptorPool используется для работы с типами протобаф, которые не могут быть предопределены заранее.
/// Это более низкоуровневый компонент по сравнению с TypeRegistry, предназначенный для динамической работы.
/// с дескрипторами и создания сообщений из FileDescriptorProto.
///
/// ## Основные возможности:.
/// - Динамическое создание дескрипторов из FileDescriptorProto.
/// - Поддержка builtin дескрипторов для стандартных типов Protocol Buffers.
/// - Поиск дескрипторов по различным критериям.
/// - Построение цепочек зависимостей между дескрипторами.
/// - Thread-safe операции для безопасного использования в многопоточной среде.
/// - Интеграция с MessageFactory для создания динамических сообщений.
public class DescriptorPool {
  // MARK: - Properties

  /// Пул файловых дескрипторов по имени.
  private var fileDescriptors: [String: FileDescriptor] = [:]

  /// Пул дескрипторов сообщений по полному имени.
  private var messageDescriptors: [String: MessageDescriptor] = [:]

  /// Пул дескрипторов перечислений по полному имени.
  private var enumDescriptors: [String: EnumDescriptor] = [:]

  /// Пул дескрипторов сервисов по полному имени.
  private var serviceDescriptors: [String: ServiceDescriptor] = [:]

  /// Пул дескрипторов полей по полному имени.
  private var fieldDescriptors: [String: FieldDescriptor] = [:]

  /// Очередь для thread-safe операций.
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.descriptorpool", attributes: .concurrent)

  /// Включает ли пул встроенные дескрипторы для стандартных типов.
  private let includeBuiltinDescriptors: Bool

  // MARK: - Initialization

  /// Создает новый экземпляр DescriptorPool.
  ///
  /// - Parameter includeBuiltinDescriptors: Если true, добавляет встроенные дескрипторы для стандартных типов Protocol Buffers.
  public init(includeBuiltinDescriptors: Bool = true) {
    self.includeBuiltinDescriptors = includeBuiltinDescriptors

    if includeBuiltinDescriptors {
      setupBuiltinDescriptors()
    }
  }

  // MARK: - FileDescriptor Management

  /// Добавляет FileDescriptor в пул.
  ///
  /// Автоматически извлекает и регистрирует все дескрипторы типов из файла.
  ///
  /// - Parameter fileDescriptor: Файловый дескриптор для добавления.
  /// - Throws: `DescriptorPoolError.duplicateFile` если файл уже существует
  /// - Throws: `DescriptorPoolError.duplicateSymbol` если какой-либо символ уже существует
  public func addFileDescriptor(_ fileDescriptor: FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      // Проверяем на дубликаты файлов
      if fileDescriptors[fileDescriptor.name] != nil {
        throw DescriptorPoolError.duplicateFile(fileDescriptor.name)
      }

      // Регистрируем файл
      fileDescriptors[fileDescriptor.name] = fileDescriptor

      // Извлекаем и регистрируем все дескрипторы из файла
      try extractDescriptorsFromFile(fileDescriptor)
    }
  }

  /// Извлекает все дескрипторы из FileDescriptor и добавляет их в пул.
  private func extractDescriptorsFromFile(_ fileDescriptor: FileDescriptor) throws {
    // Извлекаем сообщения
    for (_, messageDescriptor) in fileDescriptor.messages {
      try addMessageDescriptorRecursively(messageDescriptor)
    }

    // Извлекаем перечисления
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }

    // Извлекаем сервисы
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  /// Рекурсивно добавляет MessageDescriptor и все его вложенные типы.
  private func addMessageDescriptorRecursively(_ messageDescriptor: MessageDescriptor) throws {
    // Проверяем на дубликаты
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw DescriptorPoolError.duplicateSymbol(messageDescriptor.fullName)
    }

    // Добавляем само сообщение
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor

    // Добавляем поля сообщения
    for field in messageDescriptor.allFields() {
      let fieldFullName = "\(messageDescriptor.fullName).\(field.name)"
      fieldDescriptors[fieldFullName] = field
    }

    // Рекурсивно добавляем вложенные сообщения
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try addMessageDescriptorRecursively(nestedMessage)
    }

    // Добавляем вложенные перечисления
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Lookup Methods

  /// Находит FileDescriptor по имени файла.
  ///
  /// - Parameter fileName: Имя файла.
  /// - Returns: FileDescriptor или nil если не найден.
  public func findFileDescriptor(named fileName: String) -> FileDescriptor? {
    return accessQueue.sync {
      return fileDescriptors[fileName]
    }
  }

  /// Находит MessageDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя сообщения.
  /// - Returns: MessageDescriptor или nil если не найден.
  public func findMessageDescriptor(named fullName: String) -> MessageDescriptor? {
    return accessQueue.sync {
      return messageDescriptors[fullName]
    }
  }

  /// Находит EnumDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя перечисления.
  /// - Returns: EnumDescriptor или nil если не найден.
  public func findEnumDescriptor(named fullName: String) -> EnumDescriptor? {
    return accessQueue.sync {
      return enumDescriptors[fullName]
    }
  }

  /// Находит ServiceDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя сервиса.
  /// - Returns: ServiceDescriptor или nil если не найден.
  public func findServiceDescriptor(named fullName: String) -> ServiceDescriptor? {
    return accessQueue.sync {
      return serviceDescriptors[fullName]
    }
  }

  /// Находит FieldDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя поля (включая имя содержащего сообщения).
  /// - Returns: FieldDescriptor или nil если не найден.
  public func findFieldDescriptor(named fullName: String) -> FieldDescriptor? {
    return accessQueue.sync {
      return fieldDescriptors[fullName]
    }
  }

  /// Находит FileDescriptor, содержащий указанный символ.
  ///
  /// - Parameter symbolName: Имя символа для поиска.
  /// - Returns: FileDescriptor содержащий символ или nil если не найден.
  public func findFileContainingSymbol(_ symbolName: String) -> FileDescriptor? {
    return accessQueue.sync {
      // Ищем среди сообщений
      if let messageDescriptor = messageDescriptors[symbolName] {
        return fileDescriptors[messageDescriptor.fileDescriptorPath ?? ""]
      }

      // Ищем среди перечислений
      if let enumDescriptor = enumDescriptors[symbolName] {
        return fileDescriptors[enumDescriptor.fileDescriptorPath ?? ""]
      }

      // Ищем среди сервисов
      if let serviceDescriptor = serviceDescriptors[symbolName] {
        return fileDescriptors[serviceDescriptor.fileDescriptorPath ?? ""]
      }

      return nil
    }
  }

  // MARK: - Factory Integration Methods

  /// Создает DynamicMessage для указанного типа используя MessageFactory.
  ///
  /// - Parameter typeName: Полное имя типа сообщения.
  /// - Returns: Новое DynamicMessage или nil если тип не найден.
  public func createMessage(forType typeName: String) -> DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else {
      return nil
    }

    let factory = MessageFactory()
    return factory.createMessage(from: descriptor)
  }

  /// Создает DynamicMessage с предзаполненными значениями.
  ///
  /// - Parameters:.
  ///   - typeName: Полное имя типа сообщения.
  ///   - fieldValues: Словарь значений полей.
  /// - Returns: Новое DynamicMessage с установленными значениями или nil если тип не найден.
  /// - Throws: Ошибки создания или установки значений полей.
  public func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else {
      return nil
    }

    let factory = MessageFactory()
    return try factory.createMessage(from: descriptor, with: fieldValues)
  }

  // MARK: - Discovery Methods

  /// Возвращает все известные имена типов сообщений.
  ///
  /// - Returns: Массив полных имен всех зарегистрированных типов сообщений.
  public func allMessageTypeNames() -> [String] {
    return accessQueue.sync {
      return Array(messageDescriptors.keys).sorted()
    }
  }

  /// Возвращает все известные имена типов перечислений.
  ///
  /// - Returns: Массив полных имен всех зарегистрированных типов перечислений.
  public func allEnumTypeNames() -> [String] {
    return accessQueue.sync {
      return Array(enumDescriptors.keys).sorted()
    }
  }

  /// Возвращает все известные имена сервисов.
  ///
  /// - Returns: Массив полных имен всех зарегистрированных сервисов.
  public func allServiceNames() -> [String] {
    return accessQueue.sync {
      return Array(serviceDescriptors.keys).sorted()
    }
  }

  /// Возвращает все известные имена файлов.
  ///
  /// - Returns: Массив имен всех зарегистрированных файлов.
  public func allFileNames() -> [String] {
    return accessQueue.sync {
      return Array(fileDescriptors.keys).sorted()
    }
  }

  // MARK: - Dependency Resolution

  /// Находит все зависимости для указанного типа.
  ///
  /// - Parameter typeName: Полное имя типа.
  /// - Returns: Массив полных имен всех зависимых типов.
  /// - Throws: `DescriptorPoolError.symbolNotFound` если тип не найден
  public func findDependencies(for typeName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[typeName] else {
        throw DescriptorPoolError.symbolNotFound(typeName)
      }

      var dependencies: Set<String> = []
      collectDependencies(from: messageDescriptor, into: &dependencies)

      return Array(dependencies).sorted()
    }
  }

  /// Рекурсивно собирает зависимости.
  private func collectDependencies(from messageDescriptor: MessageDescriptor, into dependencies: inout Set<String>) {
    for field in messageDescriptor.allFields() {
      if let typeName = field.typeName, !typeName.isEmpty {
        dependencies.insert(typeName)

        // Рекурсивно обрабатываем сообщения
        if let nestedMessage = messageDescriptors[typeName] {
          collectDependencies(from: nestedMessage, into: &dependencies)
        }
      }
    }

    // Добавляем вложенные типы
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      dependencies.insert(nestedMessage.fullName)
      collectDependencies(from: nestedMessage, into: &dependencies)
    }

    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      dependencies.insert(nestedEnum.fullName)
    }
  }

  // MARK: - Built-in Descriptors

  /// Настраивает встроенные дескрипторы для стандартных типов Protocol Buffers.
  private func setupBuiltinDescriptors() {
    // Создаем файл для встроенных типов Google
    var googleProtobufFile = FileDescriptor(
      name: "google/protobuf/descriptor.proto",
      package: "google.protobuf"
    )

    // Добавляем основные well-known типы
    setupWellKnownTypes(&googleProtobufFile)

    // Регистрируем файл (без проверки ошибок для встроенных типов)
    try? addFileDescriptor(googleProtobufFile)
  }

  /// Настраивает well-known типы Google Protocol Buffers.
  private func setupWellKnownTypes(_ file: inout FileDescriptor) {
    // Any type
    var anyMessage = MessageDescriptor(name: "Any", parent: file)
    anyMessage.addField(FieldDescriptor(name: "type_url", number: 1, type: .string))
    anyMessage.addField(FieldDescriptor(name: "value", number: 2, type: .bytes))
    file.addMessage(anyMessage)

    // Timestamp type
    var timestampMessage = MessageDescriptor(name: "Timestamp", parent: file)
    timestampMessage.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    timestampMessage.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(timestampMessage)

    // Duration type
    var durationMessage = MessageDescriptor(name: "Duration", parent: file)
    durationMessage.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    durationMessage.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(durationMessage)

    // Empty type
    let emptyMessage = MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(emptyMessage)
  }

  // MARK: - Clear Methods

  /// Очищает все дескрипторы из пула.
  public func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
      fieldDescriptors.removeAll()
    }
  }
}

// MARK: - DescriptorPoolError

/// Ошибки DescriptorPool.
public enum DescriptorPoolError: Error, Equatable {
  /// Файл уже существует в пуле.
  case duplicateFile(String)

  /// Символ уже существует в пуле.
  case duplicateSymbol(String)

  /// Символ не найден в пуле.
  case symbolNotFound(String)

  /// Некорректный дескриптор.
  case invalidDescriptor(String)
}

extension DescriptorPoolError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .duplicateFile(let fileName):
      return "File '\(fileName)' already exists in descriptor pool"
    case .duplicateSymbol(let symbolName):
      return "Symbol '\(symbolName)' already exists in descriptor pool"
    case .symbolNotFound(let symbolName):
      return "Symbol '\(symbolName)' was not found in descriptor pool"
    case .invalidDescriptor(let reason):
      return "Invalid descriptor: \(reason)"
    }
  }
}
