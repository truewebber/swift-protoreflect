/**
 * EmptyHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Empty - представляет пустые сообщения без полей
 */

import Foundation
import SwiftProtobuf

// MARK: - Empty Handler

/// Обработчик для google.protobuf.Empty.
public struct EmptyHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.empty
  public static let supportPhase: WellKnownSupportPhase = .critical

  // MARK: - Empty Representation

  /// Специализированное представление Empty.
  ///
  /// Empty сообщения не содержат полей, поэтому это простая единица типа.
  public struct EmptyValue: Equatable, CustomStringConvertible {

    /// Создает единственный экземпляр EmptyValue.
    public init() {}

    /// Единственный экземпляр Empty (singleton pattern).
    public static let instance = EmptyValue()

    public var description: String {
      return "Empty"
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

    // Для Empty сообщения просто возвращаем единственный экземпляр
    return EmptyValue.instance
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard specialized is EmptyValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected EmptyValue"
      )
    }

    // Создаем дескриптор для Empty
    let emptyDescriptor = try createEmptyDescriptor()

    // Создаем пустое сообщение
    let factory = MessageFactory()
    let message = factory.createMessage(from: emptyDescriptor)

    // Empty сообщение не имеет полей, поэтому просто возвращаем созданное сообщение
    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    // EmptyValue всегда валиден
    return specialized is EmptyValue
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.Empty.
  /// - Returns: MessageDescriptor для Empty.
  /// - Throws: ReflectionError если создание неудачно.
  private static func createEmptyDescriptor() throws -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/empty.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения
    let messageDescriptor = MessageDescriptor(
      name: "Empty",
      parent: fileDescriptor
    )

    // Empty сообщение не имеет полей - только регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {

  /// Создает DynamicMessage для google.protobuf.Empty.
  /// - Returns: DynamicMessage представляющий Empty.
  /// - Throws: WellKnownTypeError.
  public static func emptyMessage() throws -> DynamicMessage {
    return try EmptyHandler.createDynamic(from: EmptyHandler.EmptyValue.instance)
  }

  /// Проверяет, является ли DynamicMessage пустым сообщением (Empty).
  /// - Returns: true если сообщение является Empty.
  public func isEmpty() -> Bool {
    return descriptor.fullName == WellKnownTypeNames.empty
  }

  /// Конвертирует DynamicMessage в EmptyValue (если это Empty).
  /// - Returns: EmptyValue.
  /// - Throws: WellKnownTypeError если сообщение не является Empty.
  public func toEmpty() throws -> EmptyHandler.EmptyValue {
    guard descriptor.fullName == WellKnownTypeNames.empty else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Empty"
      )
    }

    let empty = try EmptyHandler.createSpecialized(from: self) as! EmptyHandler.EmptyValue
    return empty
  }
}

// MARK: - Unit Type Integration

/// Extension для интеграции с Swift Void как аналогом Empty.
extension EmptyHandler.EmptyValue {

  /// Создает EmptyValue из Void.
  /// - Parameter void: Void значение.
  /// - Returns: EmptyValue.
  public static func from(_ void: Void) -> EmptyHandler.EmptyValue {
    return EmptyHandler.EmptyValue.instance
  }

  /// Конвертирует EmptyValue в Void.
  /// - Returns: Void.
  public func toVoid() {
    return ()
  }
}
