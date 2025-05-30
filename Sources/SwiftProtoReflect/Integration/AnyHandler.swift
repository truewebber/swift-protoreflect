/**
 * AnyHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Any - поддержка type erasure для произвольных типизированных сообщений
 */

import Foundation

// MARK: - Any Handler

/// Обработчик для google.protobuf.Any.
public struct AnyHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.any
  public static let supportPhase: WellKnownSupportPhase = .advanced

  // MARK: - Any Representation

  /// Специализированное представление Any.
  ///
  /// Any содержит произвольное сериализованное сообщение с URL типа для type erasure.
  public struct AnyValue: Equatable, CustomStringConvertible {

    // MARK: - Properties

    /// URL типа, который описывает тип сериализованного сообщения.
    /// Формат: type.googleapis.com/package.MessageType
    public let typeUrl: String

    /// Сериализованные данные сообщения.
    public let value: Data

    // MARK: - Initialization

    /// Создает AnyValue с указанным типом URL и данными.
    /// - Parameters:
    ///   - typeUrl: URL типа сообщения
    ///   - value: Сериализованные данные сообщения
    /// - Throws: WellKnownTypeError если type URL невалиден
    public init(typeUrl: String, value: Data) throws {
      guard Self.isValidTypeUrl(typeUrl) else {
        throw WellKnownTypeError.invalidData(
          typeName: AnyHandler.handledTypeName,
          reason: "Invalid type URL format: '\(typeUrl)'"
        )
      }
      self.typeUrl = typeUrl
      self.value = value
    }

    /// Создает AnyValue из произвольного DynamicMessage.
    /// - Parameter message: Динамическое сообщение для упаковки
    /// - Returns: AnyValue содержащий упакованное сообщение
    /// - Throws: WellKnownTypeError если упаковка неуспешна
    public static func pack(_ message: DynamicMessage) throws -> AnyValue {
      // Создаем type URL из дескриптора сообщения
      let typeUrl = Self.createTypeUrl(for: message.descriptor.fullName)
      
      // Сериализуем сообщение в бинарный формат
      let serializer = BinarySerializer()
      let serializedData = try serializer.serialize(message)
      
      return try AnyValue(typeUrl: typeUrl, value: serializedData)
    }

    /// Распаковывает Any в конкретный тип сообщения.
    /// - Parameter targetDescriptor: Дескриптор целевого типа
    /// - Returns: Распакованное динамическое сообщение
    /// - Throws: WellKnownTypeError если распаковка неуспешна
    public func unpack(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage {
      // Проверяем что type_url соответствует ожидаемому типу
      let expectedTypeName = targetDescriptor.fullName
      let actualTypeName = getTypeName()
      
      guard actualTypeName == expectedTypeName else {
        throw WellKnownTypeError.conversionFailed(
          from: "AnyValue[\(typeUrl)]",
          to: expectedTypeName,
          reason: "Type URL mismatch. Expected: \(expectedTypeName), got: \(actualTypeName)"
        )
      }
      
      // Десериализуем данные в сообщение
      if value.isEmpty {
        // Возвращаем пустое сообщение для пустых данных
        let factory = MessageFactory()
        return factory.createMessage(from: targetDescriptor)
      } else {
        let deserializer = BinaryDeserializer()
        return try deserializer.deserialize(value, using: targetDescriptor)
      }
    }

    /// Извлекает имя типа сообщения из type URL.
    /// - Returns: Полное имя типа (например, "google.protobuf.Duration")
    public func getTypeName() -> String {
      return Self.extractTypeName(from: typeUrl)
    }

    // MARK: - URL Utilities

    /// Создает type URL для указанного имени типа.
    /// - Parameter typeName: Полное имя типа
    /// - Returns: Корректно сформированный type URL
    internal static func createTypeUrl(for typeName: String) -> String {
      return "type.googleapis.com/\(typeName)"
    }

    /// Извлекает имя типа из type URL.
    /// - Parameter typeUrl: URL типа
    /// - Returns: Имя типа
    internal static func extractTypeName(from typeUrl: String) -> String {
      if let lastSlashIndex = typeUrl.lastIndex(of: "/") {
        return String(typeUrl[typeUrl.index(after: lastSlashIndex)...])
      }
      return typeUrl
    }

    /// Проверяет валидность type URL.
    /// - Parameter typeUrl: URL для проверки
    /// - Returns: true если URL валиден
    internal static func isValidTypeUrl(_ typeUrl: String) -> Bool {
      // Проверяем базовый формат
      guard !typeUrl.isEmpty else { return false }
      
      // Проверяем что есть хотя бы одна косая черта
      guard typeUrl.contains("/") else { return false }
      
      // Извлекаем имя типа
      let typeName = extractTypeName(from: typeUrl)
      guard !typeName.isEmpty else { return false }
      
      // Базовая проверка имени типа (должно содержать точку для package.Type)
      return typeName.contains(".")
    }

    // MARK: - Equatable

    public static func == (lhs: AnyValue, rhs: AnyValue) -> Bool {
      return lhs.typeUrl == rhs.typeUrl && lhs.value == rhs.value
    }

    // MARK: - CustomStringConvertible

    public var description: String {
      return "Any(typeUrl: \(typeUrl), value: \(value.count) bytes)"
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

    // Извлекаем поля type_url и value
    guard let typeUrl = try message.get(forField: "type_url") as? String else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Missing or invalid type_url field"
      )
    }

    guard let valueData = try message.get(forField: "value") as? Data else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Missing or invalid value field"
      )
    }

    return try AnyValue(typeUrl: typeUrl, value: valueData)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let anyValue = specialized as? AnyValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected AnyValue"
      )
    }

    // Создаем дескриптор для Any
    let anyDescriptor = try createAnyDescriptor()

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: anyDescriptor)

    // Устанавливаем поля
    try message.set(anyValue.typeUrl, forField: "type_url")
    try message.set(anyValue.value, forField: "value")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let anyValue = specialized as? AnyValue else { return false }
    
    // Проверяем валидность type URL
    return AnyValue.isValidTypeUrl(anyValue.typeUrl)
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.Any.
  /// - Returns: MessageDescriptor для Any.
  /// - Throws: ReflectionError если создание неудачно.
  private static func createAnyDescriptor() throws -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/any.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения Any
    var messageDescriptor = MessageDescriptor(
      name: "Any",
      parent: fileDescriptor
    )

    // Добавляем поле type_url
    let typeUrlField = FieldDescriptor(
      name: "type_url",
      number: 1,
      type: .string
    )
    messageDescriptor.addField(typeUrlField)

    // Добавляем поле value
    let valueField = FieldDescriptor(
      name: "value",
      number: 2,
      type: .bytes
    )
    messageDescriptor.addField(valueField)

    // Регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {

  /// Упаковывает DynamicMessage в google.protobuf.Any.
  /// - Returns: DynamicMessage представляющий Any.
  /// - Throws: WellKnownTypeError.
  public func packIntoAny() throws -> DynamicMessage {
    let anyValue = try AnyHandler.AnyValue.pack(self)
    return try AnyHandler.createDynamic(from: anyValue)
  }

  /// Распаковывает google.protobuf.Any в DynamicMessage.
  /// - Parameter targetDescriptor: Дескриптор целевого типа
  /// - Returns: Распакованное сообщение.
  /// - Throws: WellKnownTypeError если сообщение не является Any или типы не совпадают.
  public func unpackFromAny(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return try anyValue.unpack(to: targetDescriptor)
  }

  /// Проверяет содержит ли Any сообщение указанного типа.
  /// - Parameter typeName: Полное имя типа для проверки
  /// - Returns: true если Any содержит сообщение указанного типа
  /// - Throws: WellKnownTypeError если сообщение не является Any
  public func isAnyOf(typeName: String) throws -> Bool {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return anyValue.getTypeName() == typeName
  }

  /// Получает имя типа содержащегося в Any сообщения.
  /// - Returns: Полное имя типа сообщения
  /// - Throws: WellKnownTypeError если сообщение не является Any
  public func getAnyTypeName() throws -> String {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return anyValue.getTypeName()
  }
}

// MARK: - Type Registry Integration

extension AnyHandler.AnyValue {

  /// Распаковывает Any используя TypeRegistry для разрешения типов.
  /// - Parameter registry: Реестр типов для разрешения дескрипторов
  /// - Returns: Распакованное динамическое сообщение
  /// - Throws: WellKnownTypeError если тип не найден или десериализация неуспешна
  public func unpack(using registry: TypeRegistry) throws -> DynamicMessage {
    let typeName = getTypeName()
    
    guard let messageDescriptor = registry.findMessage(named: typeName) else {
      throw WellKnownTypeError.conversionFailed(
        from: "AnyValue",
        to: typeName,
        reason: "Message type '\(typeName)' not found in registry"
      )
    }

    return try unpack(to: messageDescriptor)
  }
}
