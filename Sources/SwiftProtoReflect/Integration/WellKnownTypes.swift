/**
 * WellKnownTypes.swift
 * SwiftProtoReflect
 *
 * Специализированная поддержка для стандартных типов Protocol Buffers (google.protobuf.*)
 * Обеспечивает оптимизированную работу с часто используемыми типами.
 */

import Foundation
import SwiftProtobuf

// MARK: - Well-Known Type Names

/// Константы для имен стандартных типов Protocol Buffers.
public struct WellKnownTypeNames {

  // MARK: - Critical Types (Phase 1)

  /// google.protobuf.Timestamp.
  public static let timestamp = "google.protobuf.Timestamp"

  /// google.protobuf.Duration.
  public static let duration = "google.protobuf.Duration"

  /// google.protobuf.Empty.
  public static let empty = "google.protobuf.Empty"

  // MARK: - Important Types (Phase 2)

  /// google.protobuf.FieldMask.
  public static let fieldMask = "google.protobuf.FieldMask"

  /// google.protobuf.Struct.
  public static let structType = "google.protobuf.Struct"

  /// google.protobuf.Value.
  public static let value = "google.protobuf.Value"

  // MARK: - Advanced Types (Phase 3)

  /// google.protobuf.Any.
  public static let any = "google.protobuf.Any"

  /// google.protobuf.ListValue.
  public static let listValue = "google.protobuf.ListValue"

  /// google.protobuf.NullValue.
  public static let nullValue = "google.protobuf.NullValue"

  // MARK: - Collections

  /// Все поддерживаемые well-known types.
  public static let allTypes: Set<String> = [
    timestamp, duration, empty,
    fieldMask, structType, value,
    any, listValue, nullValue,
  ]

  /// Critical types (Phase 1).
  public static let criticalTypes: Set<String> = [
    timestamp, duration, empty,
  ]

  /// Important types (Phase 2).
  public static let importantTypes: Set<String> = [
    fieldMask, structType, value,
  ]

  /// Advanced types (Phase 3).
  public static let advancedTypes: Set<String> = [
    any, listValue, nullValue,
  ]
}

// MARK: - Well-Known Type Detector

/// Утилиты для определения и работы с well-known types.
public struct WellKnownTypeDetector {

  /// Проверяет, является ли тип well-known.
  /// - Parameter typeName: Полное имя типа.
  /// - Returns: true если тип является well-known.
  public static func isWellKnownType(_ typeName: String) -> Bool {
    return WellKnownTypeNames.allTypes.contains(typeName)
  }

  /// Определяет фазу поддержки типа.
  /// - Parameter typeName: Полное имя типа.
  /// - Returns: Фаза поддержки или nil если тип не well-known.
  public static func getSupportPhase(for typeName: String) -> WellKnownSupportPhase? {
    if WellKnownTypeNames.criticalTypes.contains(typeName) {
      return .critical
    }
    else if WellKnownTypeNames.importantTypes.contains(typeName) {
      return .important
    }
    else if WellKnownTypeNames.advancedTypes.contains(typeName) {
      return .advanced
    }
    return nil
  }

  /// Получает простое имя типа без package prefix.
  /// - Parameter typeName: Полное имя типа.
  /// - Returns: Простое имя типа.
  public static func getSimpleName(for typeName: String) -> String? {
    guard isWellKnownType(typeName) else { return nil }
    return String(typeName.split(separator: ".").last ?? "")
  }
}

// MARK: - Support Phase

/// Фазы поддержки well-known types.
public enum WellKnownSupportPhase: Int, CaseIterable {
  case critical = 1  // Timestamp, Duration, Empty
  case important = 2  // FieldMask, Struct, Value
  case advanced = 3  // Any, ListValue, NullValue

  /// Человекочитаемое описание фазы.
  public var description: String {
    switch self {
    case .critical:
      return "Critical Types (Phase 1)"
    case .important:
      return "Important Types (Phase 2)"
    case .advanced:
      return "Advanced Types (Phase 3)"
    }
  }

  /// Типы, включенные в эту фазу.
  public var includedTypes: Set<String> {
    switch self {
    case .critical:
      return WellKnownTypeNames.criticalTypes
    case .important:
      return WellKnownTypeNames.importantTypes
    case .advanced:
      return WellKnownTypeNames.advancedTypes
    }
  }
}

// MARK: - Well-Known Type Handler Protocol

/// Протокол для обработки специфичных well-known types.
public protocol WellKnownTypeHandler {

  /// Тип, который обрабатывает этот handler.
  static var handledTypeName: String { get }

  /// Фаза поддержки.
  static var supportPhase: WellKnownSupportPhase { get }

  /// Создает специализированное представление из DynamicMessage.
  /// - Parameter message: Динамическое сообщение.
  /// - Returns: Специализированное представление.
  /// - Throws: WellKnownTypeError если конвертация невозможна.
  static func createSpecialized(from message: DynamicMessage) throws -> Any

  /// Создает DynamicMessage из специализированного представления.
  /// - Parameter specialized: Специализированное представление.
  /// - Returns: Динамическое сообщение.
  /// - Throws: WellKnownTypeError если конвертация невозможна.
  static func createDynamic(from specialized: Any) throws -> DynamicMessage

  /// Выполняет валидацию специализированного объекта.
  /// - Parameter specialized: Объект для валидации.
  /// - Returns: true если объект валиден.
  static func validate(_ specialized: Any) -> Bool
}

// MARK: - Well-Known Type Errors

/// Ошибки при работе с well-known types.
public enum WellKnownTypeError: Error, Equatable, CustomStringConvertible {

  /// Тип не поддерживается.
  case unsupportedType(String)

  /// Ошибка конвертации между типами.
  case conversionFailed(from: String, to: String, reason: String)

  /// Невалидные данные для типа.
  case invalidData(typeName: String, reason: String)

  /// Handler для типа не найден.
  case handlerNotFound(String)

  /// Ошибка валидации.
  case validationFailed(typeName: String, reason: String)

  public var description: String {
    switch self {
    case .unsupportedType(let type):
      return "Unsupported well-known type: \(type)"
    case .conversionFailed(let from, let to, let reason):
      return "Failed to convert from \(from) to \(to): \(reason)"
    case .invalidData(let typeName, let reason):
      return "Invalid data for \(typeName): \(reason)"
    case .handlerNotFound(let type):
      return "Handler not found for well-known type: \(type)"
    case .validationFailed(let typeName, let reason):
      return "Validation failed for \(typeName): \(reason)"
    }
  }
}

// MARK: - Well-Known Types Registry

/// Реестр обработчиков well-known types.
public final class WellKnownTypesRegistry {

  /// Singleton instance.
  public static let shared = WellKnownTypesRegistry()

  /// Зарегистрированные обработчики.
  private var handlers: [String: WellKnownTypeHandler.Type] = [:]

  /// Mutex для thread-safety.
  private let handlersMutex = NSLock()

  private init() {
    // Регистрируем базовые обработчики
    registerDefaultHandlers()
  }

  /// Регистрирует обработчик для типа.
  /// - Parameter handlerType: Тип обработчика.
  public func register<T: WellKnownTypeHandler>(_ handlerType: T.Type) {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    handlers[handlerType.handledTypeName] = handlerType
  }

  /// Получает обработчик для типа.
  /// - Parameter typeName: Имя типа.
  /// - Returns: Обработчик или nil если не найден.
  public func getHandler(for typeName: String) -> WellKnownTypeHandler.Type? {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    return handlers[typeName]
  }

  /// Создает специализированный объект из DynamicMessage.
  /// - Parameters:.
  ///   - message: Динамическое сообщение.
  ///   - typeName: Имя well-known типа.
  /// - Returns: Специализированный объект.
  /// - Throws: WellKnownTypeError.
  public func createSpecialized(from message: DynamicMessage, typeName: String) throws -> Any {
    guard let handler = getHandler(for: typeName) else {
      throw WellKnownTypeError.handlerNotFound(typeName)
    }

    return try handler.createSpecialized(from: message)
  }

  /// Создает DynamicMessage из специализированного объекта.
  /// - Parameters:.
  ///   - specialized: Специализированный объект.
  ///   - typeName: Имя well-known типа.
  /// - Returns: Динамическое сообщение.
  /// - Throws: WellKnownTypeError.
  public func createDynamic(from specialized: Any, typeName: String) throws -> DynamicMessage {
    guard let handler = getHandler(for: typeName) else {
      throw WellKnownTypeError.handlerNotFound(typeName)
    }

    return try handler.createDynamic(from: specialized)
  }

  /// Получает все зарегистрированные типы.
  /// - Returns: Набор имен типов.
  public func getRegisteredTypes() -> Set<String> {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    return Set(handlers.keys)
  }

  /// Очищает все зарегистрированные обработчики.
  public func clear() {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    handlers.removeAll()
  }

  // MARK: - Private Methods

  /// Регистрирует обработчики по умолчанию.
  private func registerDefaultHandlers() {
    // Critical types (Phase 1)
    register(TimestampHandler.self)
    register(DurationHandler.self)
    register(EmptyHandler.self)

    // Important types (Phase 2)
    register(FieldMaskHandler.self)
    register(StructHandler.self)
    register(ValueHandler.self)

    // Advanced types (Phase 3)
    register(AnyHandler.self)
  }
}
