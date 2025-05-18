//
// FileDescriptor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-17
//

import Foundation
import SwiftProtobuf

/// FileDescriptor
///
/// Представление .proto файла, содержащее метаданные о сообщениях, перечислениях,
/// сервисах и других элементах, определенных в файле Protocol Buffers.
public struct FileDescriptor {
  // MARK: - Properties
  
  /// Имя файла (например, "person.proto")
  public let name: String
  
  /// Пакет, к которому относится файл (например, "example.person")
  public let package: String
  
  /// Зависимости файла (импортированные .proto файлы)
  public let dependencies: [String]
  
  /// Опции файла
  public let options: [String: Any]
  
  /// Список сообщений, определенных в файле
  public private(set) var messages: [String: MessageDescriptor] = [:]
  
  /// Список перечислений, определенных в файле
  public private(set) var enums: [String: EnumDescriptor] = [:]
  
  /// Список сервисов, определенных в файле
  public private(set) var services: [String: ServiceDescriptor] = [:]
  
  // MARK: - Initialization
  
  /// Создает новый экземпляр FileDescriptor
  public init(
    name: String,
    package: String,
    dependencies: [String] = [],
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.package = package
    self.dependencies = dependencies
    self.options = options
  }
  
  // MARK: - Methods
  
  /// Добавляет дескриптор сообщения в файл
  ///
  /// - Parameter messageDescriptor: Дескриптор сообщения для добавления
  /// - Returns: Обновленный FileDescriptor
  @discardableResult
  public mutating func addMessage(_ messageDescriptor: MessageDescriptor) -> Self {
    // Создаем новое сообщение с учетом родительского файла
    var newMessage = messageDescriptor
    
    // Устанавливаем путь к файловому дескриптору, если не задан
    if newMessage.fileDescriptorPath == nil && newMessage.parentMessageFullName == nil {
      newMessage.fileDescriptorPath = self.name
    }
    
    messages[messageDescriptor.name] = newMessage
    return self
  }
  
  /// Добавляет дескриптор перечисления в файл
  ///
  /// - Parameter enumDescriptor: Дескриптор перечисления для добавления
  /// - Returns: Обновленный FileDescriptor
  @discardableResult
  public mutating func addEnum(_ enumDescriptor: EnumDescriptor) -> Self {
    enums[enumDescriptor.name] = enumDescriptor
    return self
  }
  
  /// Добавляет дескриптор сервиса в файл
  ///
  /// - Parameter serviceDescriptor: Дескриптор сервиса для добавления
  /// - Returns: Обновленный FileDescriptor
  @discardableResult
  public mutating func addService(_ serviceDescriptor: ServiceDescriptor) -> Self {
    services[serviceDescriptor.name] = serviceDescriptor
    return self
  }
  
  /// Получает полный путь для типа в этом файле
  ///
  /// - Parameter typeName: Имя типа
  /// - Returns: Полное имя с пакетом
  public func getFullName(for typeName: String) -> String {
    return package.isEmpty ? typeName : "\(package).\(typeName)"
  }
  
  /// Проверяет, содержит ли файл указанное сообщение
  ///
  /// - Parameter name: Имя сообщения
  /// - Returns: true, если сообщение существует
  public func hasMessage(named name: String) -> Bool {
    return messages[name] != nil
  }
  
  /// Проверяет, содержит ли файл указанное перечисление
  ///
  /// - Parameter name: Имя перечисления
  /// - Returns: true, если перечисление существует
  public func hasEnum(named name: String) -> Bool {
    return enums[name] != nil
  }
  
  /// Проверяет, содержит ли файл указанный сервис
  ///
  /// - Parameter name: Имя сервиса
  /// - Returns: true, если сервис существует
  public func hasService(named name: String) -> Bool {
    return services[name] != nil
  }
}

/// Заглушка для EnumDescriptor
/// TODO: Заменить на реальную реализацию из модуля Descriptor
public struct EnumDescriptor {
  public let name: String
  
  public init(name: String) {
    self.name = name
  }
}

/// Заглушка для ServiceDescriptor
/// TODO: Заменить на реальную реализацию из модуля Descriptor
public struct ServiceDescriptor {
  public let name: String
  
  public init(name: String) {
    self.name = name
  }
}
