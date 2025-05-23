//
// ServiceDescriptor.swift
// SwiftProtoReflect
//
// Создан: 2025-05-23
//

import Foundation
import SwiftProtobuf

/// ServiceDescriptor.
///
/// Дескриптор сервиса Protocol Buffers, который описывает gRPC сервис,.
/// его методы, входные и выходные типы сообщений, а также опции.
public struct ServiceDescriptor: Equatable {
  // MARK: - Types

  /// Дескриптор метода сервиса с именем, входными и выходными типами.
  public struct MethodDescriptor: Equatable {
    /// Имя метода (например, "GetUser").
    public let name: String

    /// Полное имя входного типа сообщения (например, "example.GetUserRequest").
    public let inputType: String

    /// Полное имя выходного типа сообщения (например, "example.GetUserResponse").
    public let outputType: String

    /// Указывает, является ли метод клиентским потоковым (client streaming).
    public let clientStreaming: Bool

    /// Указывает, является ли метод серверным потоковым (server streaming).
    public let serverStreaming: Bool

    /// Опции метода.
    public let options: [String: Any]

    /// Создает новый дескриптор метода.
    ///
    /// - Parameters:.
    ///   - name: Имя метода.
    ///   - inputType: Полное имя входного типа сообщения.
    ///   - outputType: Полное имя выходного типа сообщения.
    ///   - clientStreaming: Флаг клиентского потока.
    ///   - serverStreaming: Флаг серверного потока.
    ///   - options: Опции метода.
    public init(
      name: String,
      inputType: String,
      outputType: String,
      clientStreaming: Bool = false,
      serverStreaming: Bool = false,
      options: [String: Any] = [:]
    ) {
      self.name = name
      self.inputType = inputType
      self.outputType = outputType
      self.clientStreaming = clientStreaming
      self.serverStreaming = serverStreaming
      self.options = options
    }

    // MARK: - Equatable

    public static func == (lhs: MethodDescriptor, rhs: MethodDescriptor) -> Bool {
      guard
        lhs.name == rhs.name && lhs.inputType == rhs.inputType && lhs.outputType == rhs.outputType
          && lhs.clientStreaming == rhs.clientStreaming && lhs.serverStreaming == rhs.serverStreaming
      else {
        return false
      }

      // Сравниваем опции: проверяем ключи и значения
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

  /// Имя сервиса (например, "UserService").
  public let name: String

  /// Полное имя сервиса, включая пакет (например, "example.UserService").
  public let fullName: String

  /// Путь к родительскому файлу (для разрешения ссылок).
  public var fileDescriptorPath: String?

  /// Список методов сервиса по имени.
  public private(set) var methodsByName: [String: MethodDescriptor] = [:]

  /// Опции сервиса.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Создает новый экземпляр ServiceDescriptor.
  ///
  /// - Parameters:.
  ///   - name: Имя сервиса.
  ///   - fullName: Полное имя сервиса.
  ///   - options: Опции сервиса.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Создает новый экземпляр ServiceDescriptor с базовым именем.
  ///
  /// Полное имя будет сгенерировано автоматически на основе родительского файла.
  ///
  /// - Parameters:.
  ///   - name: Имя сервиса.
  ///   - parent: Родительский файл.
  ///   - options: Опции сервиса.
  public init(
    name: String,
    parent: FileDescriptor,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.options = options
    self.fullName = parent.getFullName(for: name)
    self.fileDescriptorPath = parent.name
  }

  // MARK: - Method Methods

  /// Добавляет метод к сервису.
  ///
  /// - Parameter method: Дескриптор метода для добавления.
  /// - Returns: Обновленный ServiceDescriptor.
  @discardableResult
  public mutating func addMethod(_ method: MethodDescriptor) -> Self {
    methodsByName[method.name] = method
    return self
  }

  /// Проверяет, содержит ли сервис указанный метод.
  ///
  /// - Parameter name: Имя метода.
  /// - Returns: true, если метод существует.
  public func hasMethod(named name: String) -> Bool {
    return methodsByName[name] != nil
  }

  /// Получает метод по имени.
  ///
  /// - Parameter name: Имя метода.
  /// - Returns: Дескриптор метода, если он существует.
  public func method(named name: String) -> MethodDescriptor? {
    return methodsByName[name]
  }

  /// Получает список всех методов сервиса.
  ///
  /// - Returns: Список методов.
  public func allMethods() -> [MethodDescriptor] {
    return Array(methodsByName.values)
  }

  // MARK: - Equatable

  public static func == (lhs: ServiceDescriptor, rhs: ServiceDescriptor) -> Bool {
    // Сравниваем основные свойства
    guard lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
    else {
      return false
    }

    // Сравниваем методы
    let lhsMethodsByName = lhs.methodsByName
    let rhsMethodsByName = rhs.methodsByName

    guard lhsMethodsByName.count == rhsMethodsByName.count else {
      return false
    }

    for (name, lhsMethod) in lhsMethodsByName {
      guard let rhsMethod = rhsMethodsByName[name], lhsMethod == rhsMethod else {
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
