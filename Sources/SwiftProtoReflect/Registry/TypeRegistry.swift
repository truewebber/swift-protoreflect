//
// TypeRegistry.swift
// SwiftProtoReflect
//
// Создан: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// TypeRegistry.
///
/// Централизованный реестр для управления всеми известными типами Protocol Buffers.
/// Обеспечивает регистрацию, поиск и разрешение зависимостей между типами.
///
/// ## Основные возможности:.
/// - Регистрация FileDescriptor, MessageDescriptor, EnumDescriptor, ServiceDescriptor.
/// - Быстрый поиск типов по полному имени.
/// - Автоматическое извлечение типов из FileDescriptor.
/// - Thread-safe операции.
/// - Разрешение зависимостей между типами.
public class TypeRegistry {
  // MARK: - Properties

  /// Реестр файловых дескрипторов по имени файла.
  private var fileDescriptors: [String: FileDescriptor] = [:]

  /// Реестр дескрипторов сообщений по полному имени.
  private var messageDescriptors: [String: MessageDescriptor] = [:]

  /// Реестр дескрипторов перечислений по полному имени.
  private var enumDescriptors: [String: EnumDescriptor] = [:]

  /// Реестр дескрипторов сервисов по полному имени.
  private var serviceDescriptors: [String: ServiceDescriptor] = [:]

  /// Очередь для thread-safe операций.
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.typeregistry", attributes: .concurrent)

  // MARK: - Initialization

  /// Создает новый экземпляр TypeRegistry.
  public init() {
    // Реестр инициализируется пустым
  }

  // MARK: - File Registration Methods

  /// Регистрирует FileDescriptor и автоматически извлекает все содержащиеся в нем типы.
  ///
  /// - Parameter fileDescriptor: Файловый дескриптор для регистрации.
  /// - Throws: `RegistryError.duplicateFile` если файл уже зарегистрирован
  public func registerFile(_ fileDescriptor: FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      // Проверяем на дубликаты файлов
      if fileDescriptors[fileDescriptor.name] != nil {
        throw RegistryError.duplicateFile(fileDescriptor.name)
      }

      // Регистрируем файл
      fileDescriptors[fileDescriptor.name] = fileDescriptor

      // Автоматически регистрируем все типы из файла
      try registerTypesFromFile(fileDescriptor)
    }
  }

  /// Извлекает и регистрирует все типы из FileDescriptor.
  private func registerTypesFromFile(_ fileDescriptor: FileDescriptor) throws {
    // Регистрируем все сообщения
    for (_, messageDescriptor) in fileDescriptor.messages {
      try registerMessageRecursively(messageDescriptor)
    }

    // Регистрируем все перечисления
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }

    // Регистрируем все сервисы
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  /// Рекурсивно регистрирует сообщение и все его вложенные типы.
  private func registerMessageRecursively(_ messageDescriptor: MessageDescriptor) throws {
    // Проверяем на дубликаты
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw RegistryError.duplicateType(messageDescriptor.fullName)
    }

    // Регистрируем само сообщение
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor

    // Регистрируем вложенные сообщения
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try registerMessageRecursively(nestedMessage)
    }

    // Регистрируем вложенные перечисления
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw RegistryError.duplicateType(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Direct Type Registration Methods

  /// Регистрирует MessageDescriptor напрямую.
  ///
  /// - Parameter messageDescriptor: Дескриптор сообщения.
  /// - Throws: `RegistryError.duplicateType` если тип уже зарегистрирован
  public func registerMessage(_ messageDescriptor: MessageDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      try registerMessageRecursively(messageDescriptor)
    }
  }

  /// Регистрирует EnumDescriptor напрямую.
  ///
  /// - Parameter enumDescriptor: Дескриптор перечисления.
  /// - Throws: `RegistryError.duplicateType` если тип уже зарегистрирован
  public func registerEnum(_ enumDescriptor: EnumDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
  }

  /// Регистрирует ServiceDescriptor напрямую.
  ///
  /// - Parameter serviceDescriptor: Дескриптор сервиса.
  /// - Throws: `RegistryError.duplicateType` если тип уже зарегистрирован
  public func registerService(_ serviceDescriptor: ServiceDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  // MARK: - Lookup Methods

  /// Находит FileDescriptor по имени файла.
  ///
  /// - Parameter fileName: Имя файла.
  /// - Returns: FileDescriptor или nil если не найден.
  public func findFile(named fileName: String) -> FileDescriptor? {
    return accessQueue.sync {
      return fileDescriptors[fileName]
    }
  }

  /// Находит MessageDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя сообщения.
  /// - Returns: MessageDescriptor или nil если не найден.
  public func findMessage(named fullName: String) -> MessageDescriptor? {
    return accessQueue.sync {
      return messageDescriptors[fullName]
    }
  }

  /// Находит EnumDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя перечисления.
  /// - Returns: EnumDescriptor или nil если не найден.
  public func findEnum(named fullName: String) -> EnumDescriptor? {
    return accessQueue.sync {
      return enumDescriptors[fullName]
    }
  }

  /// Находит ServiceDescriptor по полному имени.
  ///
  /// - Parameter fullName: Полное имя сервиса.
  /// - Returns: ServiceDescriptor или nil если не найден.
  public func findService(named fullName: String) -> ServiceDescriptor? {
    return accessQueue.sync {
      return serviceDescriptors[fullName]
    }
  }

  // MARK: - Query Methods

  /// Проверяет, зарегистрирован ли файл.
  ///
  /// - Parameter fileName: Имя файла.
  /// - Returns: true если файл зарегистрирован.
  public func hasFile(named fileName: String) -> Bool {
    return findFile(named: fileName) != nil
  }

  /// Проверяет, зарегистрировано ли сообщение.
  ///
  /// - Parameter fullName: Полное имя сообщения.
  /// - Returns: true если сообщение зарегистрировано.
  public func hasMessage(named fullName: String) -> Bool {
    return findMessage(named: fullName) != nil
  }

  /// Проверяет, зарегистрировано ли перечисление.
  ///
  /// - Parameter fullName: Полное имя перечисления.
  /// - Returns: true если перечисление зарегистрировано.
  public func hasEnum(named fullName: String) -> Bool {
    return findEnum(named: fullName) != nil
  }

  /// Проверяет, зарегистрирован ли сервис.
  ///
  /// - Parameter fullName: Полное имя сервиса.
  /// - Returns: true если сервис зарегистрирован.
  public func hasService(named fullName: String) -> Bool {
    return findService(named: fullName) != nil
  }

  // MARK: - Enumeration Methods

  /// Возвращает все зарегистрированные файлы.
  ///
  /// - Returns: Массив всех FileDescriptor.
  public func allFiles() -> [FileDescriptor] {
    return accessQueue.sync {
      return Array(fileDescriptors.values)
    }
  }

  /// Возвращает все зарегистрированные сообщения.
  ///
  /// - Returns: Массив всех MessageDescriptor.
  public func allMessages() -> [MessageDescriptor] {
    return accessQueue.sync {
      return Array(messageDescriptors.values)
    }
  }

  /// Возвращает все зарегистрированные перечисления.
  ///
  /// - Returns: Массив всех EnumDescriptor.
  public func allEnums() -> [EnumDescriptor] {
    return accessQueue.sync {
      return Array(enumDescriptors.values)
    }
  }

  /// Возвращает все зарегистрированные сервисы.
  ///
  /// - Returns: Массив всех ServiceDescriptor.
  public func allServices() -> [ServiceDescriptor] {
    return accessQueue.sync {
      return Array(serviceDescriptors.values)
    }
  }

  // MARK: - Dependency Resolution Methods

  /// Разрешает зависимости для указанного типа сообщения.
  ///
  /// Находит все типы, от которых зависит данное сообщение.
  /// (типы полей, вложенные типы и т.д.)
  ///
  /// - Parameter fullName: Полное имя сообщения.
  /// - Returns: Массив полных имен зависимых типов.
  /// - Throws: `RegistryError.typeNotFound` если сообщение не найдено
  public func resolveDependencies(for fullName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[fullName] else {
        throw RegistryError.typeNotFound(fullName)
      }

      var dependencies: Set<String> = []
      collectDependencies(from: messageDescriptor, into: &dependencies)

      return Array(dependencies).sorted()
    }
  }

  /// Рекурсивно собирает зависимости из MessageDescriptor.
  private func collectDependencies(from messageDescriptor: MessageDescriptor, into dependencies: inout Set<String>) {
    // Собираем зависимости из полей
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

  // MARK: - Clear Methods

  /// Очищает все зарегистрированные типы.
  public func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
    }
  }

  /// Удаляет конкретный файл и все связанные с ним типы.
  ///
  /// - Parameter fileName: Имя файла для удаления.
  /// - Returns: true если файл был найден и удален.
  public func removeFile(named fileName: String) -> Bool {
    return accessQueue.sync(flags: .barrier) {
      guard let fileDescriptor = fileDescriptors.removeValue(forKey: fileName) else {
        return false
      }

      // Удаляем все типы из этого файла
      removeTypesFromFile(fileDescriptor)
      return true
    }
  }

  /// Удаляет все типы, принадлежащие указанному файлу.
  private func removeTypesFromFile(_ fileDescriptor: FileDescriptor) {
    // Удаляем сообщения из файла
    for (_, messageDescriptor) in fileDescriptor.messages {
      removeMessageRecursively(messageDescriptor)
    }

    // Удаляем перечисления из файла
    for (_, enumDescriptor) in fileDescriptor.enums {
      enumDescriptors.removeValue(forKey: enumDescriptor.fullName)
    }

    // Удаляем сервисы из файла
    for (_, serviceDescriptor) in fileDescriptor.services {
      serviceDescriptors.removeValue(forKey: serviceDescriptor.fullName)
    }
  }

  /// Рекурсивно удаляет сообщение и все его вложенные типы.
  private func removeMessageRecursively(_ messageDescriptor: MessageDescriptor) {
    // Удаляем само сообщение
    messageDescriptors.removeValue(forKey: messageDescriptor.fullName)

    // Удаляем вложенные сообщения
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      removeMessageRecursively(nestedMessage)
    }

    // Удаляем вложенные перечисления
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      enumDescriptors.removeValue(forKey: nestedEnum.fullName)
    }
  }
}

// MARK: - RegistryError

/// Ошибки TypeRegistry.
public enum RegistryError: Error, Equatable {
  /// Файл уже зарегистрирован.
  case duplicateFile(String)

  /// Тип уже зарегистрирован.
  case duplicateType(String)

  /// Тип не найден.
  case typeNotFound(String)
}

extension RegistryError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .duplicateFile(let fileName):
      return "File '\(fileName)' is already registered"
    case .duplicateType(let typeName):
      return "Type '\(typeName)' is already registered"
    case .typeNotFound(let typeName):
      return "Type '\(typeName)' was not found in registry"
    }
  }
}
