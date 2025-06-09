/**
 * TimestampHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Timestamp - конвертация между DynamicMessage и Date
 */

import Foundation
import SwiftProtobuf

// MARK: - Timestamp Handler

/// Обработчик для google.protobuf.Timestamp.
public struct TimestampHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.timestamp
  public static let supportPhase: WellKnownSupportPhase = .critical

  // MARK: - Timestamp Representation

  /// Специализированное представление Timestamp.
  public struct TimestampValue: Equatable, CustomStringConvertible {

    /// Seconds of UTC time since Unix epoch (1970-01-01T00:00:00Z).
    public let seconds: Int64

    /// Non-negative fractions of a second at nanosecond resolution.
    public let nanos: Int32

    /// Инициализация с секундами и наносекундами.
    /// - Parameters:.
    ///   - seconds: Секунды с Unix epoch.
    ///   - nanos: Наносекунды (0-999999999).
    /// - Throws: WellKnownTypeError если значения невалидны.
    public init(seconds: Int64, nanos: Int32) throws {
      guard Self.isValidNanos(nanos) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.timestamp,
          reason: "nanos must be in range [0, 999999999], got \(nanos)"
        )
      }

      guard Self.isValidSeconds(seconds) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.timestamp,
          reason: "seconds out of valid range: \(seconds)"
        )
      }

      self.seconds = seconds
      self.nanos = nanos
    }

    /// Инициализация из Date.
    /// - Parameter date: Foundation Date.
    public init(from date: Date) {
      let timeInterval = date.timeIntervalSince1970
      self.seconds = Int64(timeInterval)
      self.nanos = Int32((timeInterval - Double(self.seconds)) * 1_000_000_000)
    }

    /// Конвертация в Date.
    /// - Returns: Foundation Date.
    public func toDate() -> Date {
      let timeInterval = Double(seconds) + Double(nanos) / 1_000_000_000.0
      return Date(timeIntervalSince1970: timeInterval)
    }

    /// Текущее время.
    /// - Returns: TimestampValue с текущим временем.
    public static func now() -> TimestampValue {
      return TimestampValue(from: Date())
    }

    public var description: String {
      let date = toDate()
      
      // Use cross-platform compatible date formatting
      #if canImport(Foundation) && !os(Linux)
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter.string(from: date)
      #else
      // Fallback for Linux and other platforms
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
      formatter.timeZone = TimeZone(identifier: "UTC")
      formatter.locale = Locale(identifier: "en_US_POSIX")
      return formatter.string(from: date)
      #endif
    }

    // MARK: - Validation

    /// Валидация наносекунд.
    /// - Parameter nanos: Значение наносекунд.
    /// - Returns: true если валидны.
    internal static func isValidNanos(_ nanos: Int32) -> Bool {
      return nanos >= 0 && nanos <= 999_999_999
    }

    /// Валидация секунд (в разумных пределах).
    /// - Parameter seconds: Значение секунд.
    /// - Returns: true если валидны.
    internal static func isValidSeconds(_ seconds: Int64) -> Bool {
      // Разрешаем от 1 января 1678 до 31 декабря 2261
      // (примерно как в оригинальном protobuf)
      return seconds >= -9_223_372_036 && seconds <= 253_402_300_799
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

    // Извлекаем поля seconds и nanos
    let secondsValue: Int64
    let nanosValue: Int32

    do {
      if try message.hasValue(forField: "seconds") {
        if let value = try message.get(forField: "seconds") as? Int64 {
          secondsValue = value
        }
        else {
          secondsValue = 0
        }
      }
      else {
        secondsValue = 0
      }

      if try message.hasValue(forField: "nanos") {
        if let value = try message.get(forField: "nanos") as? Int32 {
          nanosValue = value
        }
        else {
          nanosValue = 0
        }
      }
      else {
        nanosValue = 0
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "TimestampValue",
        reason: "Failed to extract fields: \(error.localizedDescription)"
      )
    }

    // Создаем TimestampValue
    return try TimestampValue(seconds: secondsValue, nanos: nanosValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let timestampValue = specialized as? TimestampValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected TimestampValue"
      )
    }

    // Создаем дескриптор для Timestamp
    let timestampDescriptor = createTimestampDescriptor()

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: timestampDescriptor)

    // Устанавливаем поля
    try message.set(timestampValue.seconds, forField: "seconds")
    try message.set(timestampValue.nanos, forField: "nanos")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let timestampValue = specialized as? TimestampValue else {
      return false
    }

    return TimestampValue.isValidNanos(timestampValue.nanos) && TimestampValue.isValidSeconds(timestampValue.seconds)
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.Timestamp.
  /// - Returns: MessageDescriptor для Timestamp.
  private static func createTimestampDescriptor() -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/timestamp.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения
    var messageDescriptor = MessageDescriptor(
      name: "Timestamp",
      parent: fileDescriptor
    )

    // Добавляем поле seconds
    let secondsField = FieldDescriptor(
      name: "seconds",
      number: 1,
      type: .int64
    )
    messageDescriptor.addField(secondsField)

    // Добавляем поле nanos
    let nanosField = FieldDescriptor(
      name: "nanos",
      number: 2,
      type: .int32
    )
    messageDescriptor.addField(nanosField)

    // Регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension Date {

  /// Создает Date из TimestampValue.
  /// - Parameter timestamp: TimestampValue.
  /// - Returns: Date.
  public init(from timestamp: TimestampHandler.TimestampValue) {
    self = timestamp.toDate()
  }

  /// Конвертирует Date в TimestampValue.
  /// - Returns: TimestampValue.
  public func toTimestampValue() -> TimestampHandler.TimestampValue {
    return TimestampHandler.TimestampValue(from: self)
  }
}

extension DynamicMessage {

  /// Создает DynamicMessage из Date для google.protobuf.Timestamp.
  /// - Parameter date: Foundation Date.
  /// - Returns: DynamicMessage представляющий Timestamp.
  /// - Throws: WellKnownTypeError.
  public static func timestampMessage(from date: Date) throws -> DynamicMessage {
    let timestamp = TimestampHandler.TimestampValue(from: date)
    return try TimestampHandler.createDynamic(from: timestamp)
  }

  /// Конвертирует DynamicMessage в Date (если это Timestamp).
  /// - Returns: Date.
  /// - Throws: WellKnownTypeError если сообщение не является Timestamp.
  public func toDate() throws -> Date {
    guard descriptor.fullName == WellKnownTypeNames.timestamp else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Timestamp"
      )
    }

    let timestamp = try TimestampHandler.createSpecialized(from: self) as! TimestampHandler.TimestampValue
    return timestamp.toDate()
  }
}
