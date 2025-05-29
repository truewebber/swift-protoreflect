//
// StaticMessageBridge.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// StaticMessageBridge обеспечивает конвертацию между статическими Swift Protobuf сообщениями.
/// и динамическими DynamicMessage объектами.
///
/// Этот компонент позволяет:.
/// - Конвертировать статические сообщения в динамические для рефлексии.
/// - Создавать статические сообщения из динамических для интеграции с существующим кодом.
/// - Обеспечивать совместимость между статическим и динамическим подходами.
public struct StaticMessageBridge {

  // MARK: - Initialization

  /// Создает новый экземпляр StaticMessageBridge.
  public init() {}

  // MARK: - Static to Dynamic Conversion

  /// Конвертирует статическое Swift Protobuf сообщение в динамическое DynamicMessage.
  ///
  /// - Parameters:.
  ///   - staticMessage: Статическое сообщение для конвертации.
  ///   - descriptor: Дескриптор для создания динамического сообщения.
  /// - Returns: Динамическое сообщение с данными из статического.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T,
    using descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    // Сериализуем статическое сообщение в бинарный формат
    let binaryData = try staticMessage.serializedData()

    // Десериализуем в динамическое сообщение
    let deserializer = BinaryDeserializer()
    return try deserializer.deserialize(binaryData, using: descriptor)
  }

  /// Конвертирует статическое Swift Protobuf сообщение в динамическое DynamicMessage.
  /// с автоматическим созданием дескриптора.
  ///
  /// - Parameter staticMessage: Статическое сообщение для конвертации.
  /// - Returns: Динамическое сообщение с данными из статического.
  /// - Throws: Ошибку, если конвертация невозможна или дескриптор не может быть создан.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> DynamicMessage {
    // Создаем дескриптор из статического сообщения
    let descriptor = try createDescriptor(from: staticMessage)

    // Конвертируем с использованием созданного дескриптора
    return try toDynamicMessage(from: staticMessage, using: descriptor)
  }

  // MARK: - Dynamic to Static Conversion

  /// Конвертирует динамическое DynamicMessage в статическое Swift Protobuf сообщение.
  ///
  /// - Parameters:.
  ///   - dynamicMessage: Динамическое сообщение для конвертации.
  ///   - messageType: Тип статического сообщения для создания.
  /// - Returns: Статическое сообщение с данными из динамического.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toStaticMessage<T: SwiftProtobuf.Message>(
    from dynamicMessage: DynamicMessage,
    as messageType: T.Type
  ) throws -> T {
    // Сериализуем динамическое сообщение в бинарный формат
    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(dynamicMessage)

    // Десериализуем в статическое сообщение
    return try T(serializedBytes: binaryData)
  }

  // MARK: - Batch Conversion Methods

  /// Конвертирует массив статических сообщений в массив динамических.
  ///
  /// - Parameters:.
  ///   - staticMessages: Массив статических сообщений.
  ///   - descriptor: Дескриптор для создания динамических сообщений.
  /// - Returns: Массив динамических сообщений.
  /// - Throws: Ошибку, если какая-либо конвертация невозможна.
  public func toDynamicMessages<T: SwiftProtobuf.Message>(
    from staticMessages: [T],
    using descriptor: MessageDescriptor
  ) throws -> [DynamicMessage] {
    return try staticMessages.map { staticMessage in
      try toDynamicMessage(from: staticMessage, using: descriptor)
    }
  }

  /// Конвертирует массив динамических сообщений в массив статических.
  ///
  /// - Parameters:.
  ///   - dynamicMessages: Массив динамических сообщений.
  ///   - messageType: Тип статических сообщений для создания.
  /// - Returns: Массив статических сообщений.
  /// - Throws: Ошибку, если какая-либо конвертация невозможна.
  public func toStaticMessages<T: SwiftProtobuf.Message>(
    from dynamicMessages: [DynamicMessage],
    as messageType: T.Type
  ) throws -> [T] {
    return try dynamicMessages.map { dynamicMessage in
      try toStaticMessage(from: dynamicMessage, as: messageType)
    }
  }

  // MARK: - Validation Methods

  /// Проверяет совместимость статического сообщения с дескриптором.
  ///
  /// - Parameters:.
  ///   - staticMessage: Статическое сообщение для проверки.
  ///   - descriptor: Дескриптор для сравнения.
  /// - Returns: true, если сообщение совместимо с дескриптором.
  public func isCompatible<T: SwiftProtobuf.Message>(
    staticMessage: T,
    with descriptor: MessageDescriptor
  ) -> Bool {
    do {
      // Пытаемся конвертировать и проверяем, что не возникает ошибок
      _ = try toDynamicMessage(from: staticMessage, using: descriptor)
      return true
    }
    catch {
      return false
    }
  }

  /// Проверяет совместимость динамического сообщения с типом статического сообщения.
  ///
  /// - Parameters:.
  ///   - dynamicMessage: Динамическое сообщение для проверки.
  ///   - messageType: Тип статического сообщения для сравнения.
  /// - Returns: true, если сообщение совместимо с типом.
  public func isCompatible<T: SwiftProtobuf.Message>(
    dynamicMessage: DynamicMessage,
    with messageType: T.Type
  ) -> Bool {
    do {
      // Пытаемся конвертировать и проверяем, что не возникает ошибок
      _ = try toStaticMessage(from: dynamicMessage, as: messageType)
      return true
    }
    catch {
      return false
    }
  }

  // MARK: - Helper Methods

  /// Создает MessageDescriptor из статического Swift Protobuf сообщения.
  ///
  /// - Parameter staticMessage: Статическое сообщение.
  /// - Returns: Дескриптор сообщения.
  /// - Throws: Ошибку, если дескриптор не может быть создан.
  private func createDescriptor<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> MessageDescriptor {
    // Получаем имя типа сообщения
    let typeName = String(describing: T.self)

    // Создаем базовый дескриптор
    // В реальной реализации здесь должна быть логика извлечения
    // метаданных из статического сообщения через рефлексию
    let descriptor = MessageDescriptor(name: typeName)

    // TODO: Реализовать извлечение полей из статического сообщения
    // Это требует более глубокой интеграции с Swift Protobuf

    return descriptor
  }
}

/// Ошибки, возникающие при работе с StaticMessageBridge.
public enum StaticMessageBridgeError: Error, LocalizedError {
  case incompatibleTypes(staticType: String, descriptorType: String)
  case serializationFailed(underlying: Error)
  case deserializationFailed(underlying: Error)
  case descriptorCreationFailed(messageType: String)
  case unsupportedMessageType(String)

  public var errorDescription: String? {
    switch self {
    case .incompatibleTypes(let staticType, let descriptorType):
      return "Несовместимые типы: статический тип '\(staticType)' не соответствует дескриптору '\(descriptorType)'"
    case .serializationFailed(let underlying):
      return "Ошибка сериализации: \(underlying.localizedDescription)"
    case .deserializationFailed(let underlying):
      return "Ошибка десериализации: \(underlying.localizedDescription)"
    case .descriptorCreationFailed(let messageType):
      return "Не удалось создать дескриптор для типа сообщения '\(messageType)'"
    case .unsupportedMessageType(let messageType):
      return "Неподдерживаемый тип сообщения: '\(messageType)'"
    }
  }
}

// MARK: - Extensions

/// Расширение DynamicMessage для удобной конвертации в статические сообщения.
extension DynamicMessage {

  /// Конвертирует это динамическое сообщение в статическое Swift Protobuf сообщение.
  ///
  /// - Parameter messageType: Тип статического сообщения для создания.
  /// - Returns: Статическое сообщение с данными из этого динамического.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toStaticMessage<T: SwiftProtobuf.Message>(as messageType: T.Type) throws -> T {
    let bridge = StaticMessageBridge()
    return try bridge.toStaticMessage(from: self, as: messageType)
  }
}

/// Расширение для Swift Protobuf Message для удобной конвертации в динамические сообщения.
extension SwiftProtobuf.Message {

  /// Конвертирует это статическое сообщение в динамическое DynamicMessage.
  ///
  /// - Parameter descriptor: Дескриптор для создания динамического сообщения.
  /// - Returns: Динамическое сообщение с данными из этого статического.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toDynamicMessage(using descriptor: MessageDescriptor) throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self, using: descriptor)
  }

  /// Конвертирует это статическое сообщение в динамическое DynamicMessage.
  /// с автоматическим созданием дескриптора.
  ///
  /// - Returns: Динамическое сообщение с данными из этого статического.
  /// - Throws: Ошибку, если конвертация невозможна или дескриптор не может быть создан.
  public func toDynamicMessage() throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self)
  }
}
