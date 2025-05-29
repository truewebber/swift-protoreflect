/**
 * FieldMaskHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.FieldMask - маски полей для partial updates
 */

import Foundation
import SwiftProtobuf

// MARK: - FieldMask Handler

/// Обработчик для google.protobuf.FieldMask.
public struct FieldMaskHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.fieldMask
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - FieldMask Representation

  /// Специализированное представление FieldMask.
  public struct FieldMaskValue: Equatable, CustomStringConvertible {

    /// Пути к полям.
    public let paths: [String]

    /// Инициализация с путями к полям.
    /// - Parameter paths: Список путей к полям.
    /// - Throws: WellKnownTypeError если пути невалидны.
    public init(paths: [String]) throws {
      for path in paths {
        guard Self.isValidPath(path) else {
          throw WellKnownTypeError.invalidData(
            typeName: WellKnownTypeNames.fieldMask,
            reason:
              "Invalid field path: '\(path)'. Path must not be empty and can only contain alphanumeric characters, dots, and underscores."
          )
        }
      }

      self.paths = paths
    }

    /// Инициализация с одним путем.
    /// - Parameter path: Путь к полю.
    /// - Throws: WellKnownTypeError если путь невалиден.
    public init(path: String) throws {
      try self.init(paths: [path])
    }

    /// Инициализация пустой маски.
    public init() {
      self.paths = []
    }

    /// Проверяет, содержит ли маска указанный путь.
    /// - Parameter path: Путь для проверки.
    /// - Returns: true если путь содержится в маске.
    public func contains(_ path: String) -> Bool {
      return paths.contains(path)
    }

    /// Проверяет, содержит ли маска путь или его родительский путь.
    /// - Parameter path: Путь для проверки.
    /// - Returns: true если путь или его родитель содержится в маске.
    public func covers(_ path: String) -> Bool {
      // Проверяем точное совпадение
      if paths.contains(path) {
        return true
      }

      // Проверяем, есть ли родительский путь в маске
      let components = path.split(separator: ".").map(String.init)
      for i in 1..<components.count {
        let parentPath = components[0..<i].joined(separator: ".")
        if paths.contains(parentPath) {
          return true
        }
      }

      return false
    }

    /// Добавляет путь к маске.
    /// - Parameter path: Путь для добавления.
    /// - Returns: Новая FieldMaskValue с добавленным путем.
    /// - Throws: WellKnownTypeError если путь невалиден.
    public func adding(_ path: String) throws -> FieldMaskValue {
      guard Self.isValidPath(path) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.fieldMask,
          reason: "Invalid field path: '\(path)'"
        )
      }

      var newPaths = paths
      if !newPaths.contains(path) {
        newPaths.append(path)
      }
      return try FieldMaskValue(paths: newPaths)
    }

    /// Удаляет путь из маски.
    /// - Parameter path: Путь для удаления.
    /// - Returns: Новая FieldMaskValue без указанного пути.
    public func removing(_ path: String) -> FieldMaskValue {
      let newPaths = paths.filter { $0 != path }
      return try! FieldMaskValue(paths: newPaths)  // Безопасно, так как удаляем валидные пути
    }

    /// Объединяет две маски полей.
    /// - Parameter other: Другая маска для объединения.
    /// - Returns: Новая FieldMaskValue с объединенными путями.
    public func union(_ other: FieldMaskValue) -> FieldMaskValue {
      let combinedPaths = Array(Set(paths + other.paths)).sorted()
      return try! FieldMaskValue(paths: combinedPaths)  // Безопасно, так как объединяем валидные пути
    }

    /// Пересечение двух масок полей.
    /// - Parameter other: Другая маска для пересечения.
    /// - Returns: Новая FieldMaskValue с пересечением путей.
    public func intersection(_ other: FieldMaskValue) -> FieldMaskValue {
      let intersectionPaths = paths.filter { other.paths.contains($0) }
      return try! FieldMaskValue(paths: intersectionPaths)  // Безопасно, так как фильтруем валидные пути
    }

    /// Пустая маска полей.
    /// - Returns: FieldMaskValue без путей.
    public static func empty() -> FieldMaskValue {
      return FieldMaskValue()
    }

    /// Маска со всеми указанными полями.
    /// - Parameter paths: Пути к полям.
    /// - Returns: FieldMaskValue с указанными путями.
    /// - Throws: WellKnownTypeError если какой-либо путь невалиден.
    public static func with(paths: [String]) throws -> FieldMaskValue {
      return try FieldMaskValue(paths: paths)
    }

    public var description: String {
      if paths.isEmpty {
        return "FieldMask(empty)"
      }
      return "FieldMask(\(paths.joined(separator: ", ")))"
    }

    // MARK: - Validation

    /// Валидация пути к полю.
    /// - Parameter path: Путь для валидации.
    /// - Returns: true если путь валиден.
    internal static func isValidPath(_ path: String) -> Bool {
      // Путь не должен быть пустым
      guard !path.isEmpty else {
        return false
      }

      // Путь может содержать только буквы, цифры, точки и подчеркивания
      let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "._"))
      return path.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Проверяем тип сообщения
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Извлекаем поле paths
    let pathsValue: [String]

    do {
      if try message.hasValue(forField: "paths") {
        if let value = try message.get(forField: "paths") as? [String] {
          pathsValue = value
        }
        else {
          pathsValue = []
        }
      }
      else {
        pathsValue = []
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "FieldMaskValue",
        reason: "Failed to extract paths field: \(error.localizedDescription)"
      )
    }

    // Создаем FieldMaskValue
    return try FieldMaskValue(paths: pathsValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected FieldMaskValue"
      )
    }

    // Создаем дескриптор для FieldMask
    let fieldMaskDescriptor = try createFieldMaskDescriptor()

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: fieldMaskDescriptor)

    // Устанавливаем поле paths
    try message.set(fieldMaskValue.paths, forField: "paths")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      return false
    }

    // Проверяем все пути в маске
    return fieldMaskValue.paths.allSatisfy { FieldMaskValue.isValidPath($0) }
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.FieldMask.
  /// - Returns: MessageDescriptor для FieldMask.
  /// - Throws: ReflectionError если создание неудачно.
  private static func createFieldMaskDescriptor() throws -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/field_mask.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения
    var messageDescriptor = MessageDescriptor(
      name: "FieldMask",
      parent: fileDescriptor
    )

    // Добавляем поле paths
    let pathsField = FieldDescriptor(
      name: "paths",
      number: 1,
      type: .string,
      isRepeated: true
    )
    messageDescriptor.addField(pathsField)

    // Регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension Array where Element == String {

  /// Создает FieldMaskValue из массива строк.
  /// - Returns: FieldMaskValue.
  /// - Throws: WellKnownTypeError если какой-либо путь невалиден.
  public func toFieldMaskValue() throws -> FieldMaskHandler.FieldMaskValue {
    return try FieldMaskHandler.FieldMaskValue(paths: self)
  }
}

extension DynamicMessage {

  /// Создает DynamicMessage из массива путей для google.protobuf.FieldMask.
  /// - Parameter paths: Пути к полям.
  /// - Returns: DynamicMessage представляющий FieldMask.
  /// - Throws: WellKnownTypeError.
  public static func fieldMaskMessage(from paths: [String]) throws -> DynamicMessage {
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: paths)
    return try FieldMaskHandler.createDynamic(from: fieldMask)
  }

  /// Конвертирует DynamicMessage в массив путей (если это FieldMask).
  /// - Returns: Массив путей к полям.
  /// - Throws: WellKnownTypeError если сообщение не является FieldMask.
  public func toFieldPaths() throws -> [String] {
    guard descriptor.fullName == WellKnownTypeNames.fieldMask else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a FieldMask"
      )
    }

    let fieldMask = try FieldMaskHandler.createSpecialized(from: self) as! FieldMaskHandler.FieldMaskValue
    return fieldMask.paths
  }
}
